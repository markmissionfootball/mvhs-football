import * as admin from "firebase-admin";

/**
 * COMPLIANCE-CRITICAL audience spec.
 *
 * A broadcast is addressed to roles + levels, never to an individual student.
 * Resolution happens here, server-side, so a coach can never bypass the UI to
 * privately target one minor — the smallest possible audience is still a role.
 */
export interface AudienceSpec {
  programId?: string | null;
  roles?: string[]; // 'player' | 'parent' | 'coach' — empty = all
  levels?: string[]; // 'varsity' | 'jv' | 'freshman' — empty = all
}

export interface ResolvedAudience {
  uids: string[];
  byRole: Record<string, number>;
}

const ALL_ROLES = ["player", "parent", "coach"];

/**
 * Resolves an audience spec to a deduplicated set of user uids, plus a
 * per-role breakdown for the compose-screen counter.
 *
 * - players: matched by `players.team` (level) + active, then mapped to the
 *   user account via `users.linkedPlayerId`.
 * - parents: the user accounts (role=parent) linked to those same players.
 * - coaches: user accounts with role=coach (not level-scoped — coaches span
 *   levels), optionally narrowed by program when programId is supplied.
 */
export async function resolveAudience(
  spec: AudienceSpec
): Promise<ResolvedAudience> {
  const db = admin.firestore();
  const roles = spec.roles && spec.roles.length > 0 ? spec.roles : ALL_ROLES;
  const levels = spec.levels ?? [];

  const byRole: Record<string, number> = {};
  const uidSet = new Set<string>();

  // Resolve the set of player ids in scope (shared by player + parent roles).
  let playerIds: string[] = [];
  const needsPlayers = roles.includes("player") || roles.includes("parent");
  if (needsPlayers) {
    playerIds = await resolvePlayerIds(db, levels, spec.programId);
  }

  // ── Players ──────────────────────────────────────────────
  if (roles.includes("player")) {
    const uids = await usersForPlayers(db, playerIds, "player");
    uids.forEach((u) => uidSet.add(u));
    byRole["player"] = uids.length;
  }

  // ── Parents ──────────────────────────────────────────────
  if (roles.includes("parent")) {
    const uids = await usersForPlayers(db, playerIds, "parent");
    uids.forEach((u) => uidSet.add(u));
    byRole["parent"] = uids.length;
  }

  // ── Coaches ──────────────────────────────────────────────
  if (roles.includes("coach")) {
    let q: admin.firestore.Query = db
      .collection("users")
      .where("role", "==", "coach");
    if (spec.programId) {
      q = q.where("programId", "==", spec.programId);
    }
    const snap = await q.get();
    const uids = snap.docs.map((d) => d.id);
    uids.forEach((u) => uidSet.add(u));
    byRole["coach"] = uids.length;
  }

  return { uids: Array.from(uidSet), byRole };
}

async function resolvePlayerIds(
  db: admin.firestore.Firestore,
  levels: string[],
  programId?: string | null
): Promise<string[]> {
  const ids = new Set<string>();

  // Firestore can't do an OR across `team` values in one query, so fan out by
  // level. No levels selected = all active players.
  const queries: admin.firestore.Query[] = [];
  if (levels.length === 0) {
    let q: admin.firestore.Query = db
      .collection("players")
      .where("active", "==", true);
    if (programId) q = q.where("programId", "==", programId);
    queries.push(q);
  } else {
    for (const level of levels) {
      let q: admin.firestore.Query = db
        .collection("players")
        .where("active", "==", true)
        .where("team", "==", level);
      if (programId) q = q.where("programId", "==", programId);
      queries.push(q);
    }
  }

  const snaps = await Promise.all(queries.map((q) => q.get()));
  for (const snap of snaps) {
    snap.docs.forEach((d) => ids.add(d.id));
  }
  return Array.from(ids);
}

/**
 * Maps a set of player ids to user-account uids for a given role.
 * Chunks the `in` queries to respect Firestore's 30-value limit.
 */
async function usersForPlayers(
  db: admin.firestore.Firestore,
  playerIds: string[],
  role: string
): Promise<string[]> {
  if (playerIds.length === 0) return [];
  const uids = new Set<string>();

  for (const chunk of chunked(playerIds, 30)) {
    const snap = await db
      .collection("users")
      .where("role", "==", role)
      .where("linkedPlayerId", "in", chunk)
      .get();
    snap.docs.forEach((d) => uids.add(d.id));
  }
  return Array.from(uids);
}

function chunked<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}
