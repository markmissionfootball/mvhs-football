import * as admin from "firebase-admin";

/**
 * Append-only oversight log. Every broadcast send, reply, reply removal, and
 * mute action lands here so administrators have a complete, tamper-evident
 * record. Written only by Cloud Functions; admins read, no one edits or deletes
 * (enforced in firestore.rules).
 */
export interface AuditEntry {
  type:
    | "broadcast_sent"
    | "reply_posted"
    | "reply_deleted"
    | "user_muted"
    | "user_unmuted";
  actorUid: string;
  actorName: string;
  broadcastId?: string;
  targetUid?: string;
  meta?: Record<string, unknown>;
}

export async function logAudit(
  db: admin.firestore.Firestore,
  entry: AuditEntry
): Promise<void> {
  try {
    await db.collection("messageAudit").add({
      ...entry,
      meta: entry.meta ?? {},
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    // Audit must never break the primary action; log and continue.
    console.error("audit write failed", e);
  }
}
