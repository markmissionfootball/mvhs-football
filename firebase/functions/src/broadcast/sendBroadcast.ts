import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { AudienceSpec, resolveAudience } from "./audience";
import { dispatch, Recipient, totalDelivery } from "./providers";
import { logAudit } from "./audit";

const VALID_ROLES = new Set(["player", "parent", "coach"]);
const VALID_LEVELS = new Set(["varsity", "jv", "freshman"]);
const VALID_CHANNELS = new Set(["push", "email", "sms"]);
const MAX_BODY = 4000;

interface SendPayload {
  subject?: string | null;
  body: string;
  audience: AudienceSpec;
  channels: string[];
  allowReplies?: boolean;
  priority?: string;
}

/** Loads the caller's user doc and asserts coach/admin authority. */
async function requireSender(request: CallableRequest): Promise<{
  uid: string;
  name: string;
  role: string;
}> {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to send a broadcast.");
  }
  const userSnap = await admin.firestore().doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new HttpsError("permission-denied", "No user profile found.");
  }
  const user = userSnap.data()!;
  const role = user.role as string;
  if (role !== "coach" && role !== "admin") {
    // Only staff may broadcast. Players/parents cannot address groups.
    throw new HttpsError(
      "permission-denied",
      "Only coaches and admins can send broadcasts."
    );
  }
  return { uid, name: user.displayName ?? "Staff", role };
}

/** Normalizes + validates an inbound audience spec. */
function sanitizeAudience(raw: AudienceSpec | undefined): AudienceSpec {
  const roles = (raw?.roles ?? []).filter((r) => VALID_ROLES.has(r));
  const levels = (raw?.levels ?? []).filter((l) => VALID_LEVELS.has(l));
  return {
    programId: raw?.programId ?? null,
    roles,
    levels,
  };
}

/**
 * sendBroadcast — the single authority for compliant one-to-many sends.
 *
 * Enforces, in order:
 *  1. Caller is a coach/admin (no member-initiated broadcasts).
 *  2. Audience is role/level-based; the client cannot pass a recipient list,
 *     so the smallest possible audience is still a role — never one student.
 *  3. Recipients are resolved server-side and snapshotted onto the doc for audit.
 *  4. Fan-out runs across the requested channels (email/SMS leave from the
 *     platform identity, not the coach).
 *  5. The send is written to the append-only audit log.
 */
export const sendBroadcast = onCall(async (request) => {
  const sender = await requireSender(request);
  const payload = request.data as SendPayload;

  const body = (payload.body ?? "").trim();
  if (!body) {
    throw new HttpsError("invalid-argument", "Message body is required.");
  }
  if (body.length > MAX_BODY) {
    throw new HttpsError("invalid-argument", "Message is too long.");
  }

  const channels = (payload.channels ?? ["push"]).filter((c) =>
    VALID_CHANNELS.has(c)
  );
  if (channels.length === 0) channels.push("push");

  const audience = sanitizeAudience(payload.audience);
  const subject = (payload.subject ?? "").trim() || null;
  const priority = payload.priority === "urgent" ? "urgent" : "normal";
  const allowReplies = payload.allowReplies !== false;

  const db = admin.firestore();

  // 1) Resolve audience → recipient uids (server-authoritative).
  const resolved = await resolveAudience(audience);
  if (resolved.uids.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No recipients match that audience."
    );
  }

  // 2) Create the broadcast doc in 'sending' state (immutable audit snapshot).
  const ref = db.collection("broadcasts").doc();
  await ref.set({
    senderUid: sender.uid,
    senderName: sender.name,
    senderRole: sender.role,
    subject,
    body,
    audience,
    recipientUids: resolved.uids,
    recipientCount: resolved.uids.length,
    channels,
    allowReplies,
    priority,
    status: "sending",
    delivery: {},
    readBy: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sentAt: null,
  });

  // 3) Hydrate recipient contact info for fan-out.
  const recipients = await loadRecipients(db, resolved.uids);

  // 4) Dispatch across channels.
  const title = subject ?? `${sender.name}`;
  let byChannel: Record<string, { sent: number; failed: number }> = {};
  let status = "sent";
  try {
    byChannel = await dispatch(channels, recipients, {
      title,
      subject: subject ?? "New message",
      body,
      broadcastId: ref.id,
      priority,
    });
  } catch (e) {
    console.error("broadcast dispatch failed", e);
    status = "failed";
  }

  await ref.update({
    status,
    delivery: byChannel,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 5) Audit.
  const totals = totalDelivery(byChannel);
  await logAudit(db, {
    type: "broadcast_sent",
    actorUid: sender.uid,
    actorName: sender.name,
    broadcastId: ref.id,
    meta: {
      audience,
      channels,
      recipientCount: resolved.uids.length,
      delivered: totals.sent,
      failed: totals.failed,
      priority,
    },
  });

  return {
    ok: status === "sent",
    broadcastId: ref.id,
    recipientCount: resolved.uids.length,
    delivery: byChannel,
    error: status === "failed" ? "Delivery failed" : null,
  };
});

/**
 * previewBroadcastAudience — read-only recipient-count estimate for the compose
 * screen's live counter. Staff-only; does not send anything.
 */
export const previewBroadcastAudience = onCall(async (request) => {
  await requireSender(request);
  const audience = sanitizeAudience(request.data as AudienceSpec);
  const resolved = await resolveAudience(audience);
  return { total: resolved.uids.length, byRole: resolved.byRole };
});

async function loadRecipients(
  db: admin.firestore.Firestore,
  uids: string[]
): Promise<Recipient[]> {
  const out: Recipient[] = [];
  // getAll handles up to a large batch; chunk to stay well within limits.
  for (const group of chunk(uids, 100)) {
    const refs = group.map((u) => db.doc(`users/${u}`));
    const snaps = await db.getAll(...refs);
    for (const snap of snaps) {
      if (!snap.exists) continue;
      const d = snap.data()!;
      out.push({
        uid: snap.id,
        displayName: d.displayName ?? "",
        email: d.email ?? null,
        phoneNumber: d.phoneNumber ?? null,
        phoneVerified: d.phoneVerified ?? false,
        fcmTokens: (d.fcmTokens as string[]) ?? [],
      });
    }
  }
  return out;
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}
