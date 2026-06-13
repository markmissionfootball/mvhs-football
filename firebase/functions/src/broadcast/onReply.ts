import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

import { logAudit } from "./audit";

/**
 * New public reply → notify everyone else in the broadcast audience and log it.
 *
 * Replies are visible to the whole group by design (the audit-trail mechanism),
 * so the notification fans out to all recipients except the reply's author.
 */
export const onNewBroadcastReply = onDocumentCreated(
  "broadcasts/{broadcastId}/replies/{replyId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const reply = snap.data();
    const broadcastId = event.params.broadcastId;
    const db = admin.firestore();

    const bSnap = await db.doc(`broadcasts/${broadcastId}`).get();
    if (!bSnap.exists) return;
    const broadcast = bSnap.data()!;

    // Audit every reply.
    await logAudit(db, {
      type: "reply_posted",
      actorUid: reply.senderUid,
      actorName: reply.senderName ?? "",
      broadcastId,
      meta: { replyId: event.params.replyId },
    });

    // Notify the group (minus the author).
    const recipientUids: string[] = (broadcast.recipientUids ?? []).filter(
      (u: string) => u !== reply.senderUid
    );
    // Always loop the original sender in on replies to their broadcast.
    if (
      broadcast.senderUid &&
      broadcast.senderUid !== reply.senderUid &&
      !recipientUids.includes(broadcast.senderUid)
    ) {
      recipientUids.push(broadcast.senderUid);
    }
    if (recipientUids.length === 0) return;

    const tokens = await tokensFor(db, recipientUids);
    if (tokens.length === 0) return;

    const title = broadcast.subject
      ? `Reply · ${broadcast.subject}`
      : "New reply";
    const body = `${reply.senderName ?? "Someone"}: ${truncate(
      reply.body ?? "",
      100
    )}`;

    for (const batch of chunk(tokens, 500)) {
      await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: { type: "broadcast_reply", broadcastId },
        apns: { payload: { aps: { sound: "default" } } },
      });
    }
  }
);

/**
 * Reply soft-deleted → log it for oversight. The document is never hard-deleted,
 * so admins retain the full record of what was said and who removed it.
 */
export const onBroadcastReplyUpdated = onDocumentUpdated(
  "broadcasts/{broadcastId}/replies/{replyId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.deleted === true || after.deleted !== true) return;

    await logAudit(admin.firestore(), {
      type: "reply_deleted",
      actorUid: after.deletedBy ?? "unknown",
      actorName: "Admin",
      broadcastId: event.params.broadcastId,
      targetUid: after.senderUid,
      meta: {
        replyId: event.params.replyId,
        reason: after.deletedReason ?? null,
      },
    });
  }
);

async function tokensFor(
  db: admin.firestore.Firestore,
  uids: string[]
): Promise<string[]> {
  const tokens: string[] = [];
  for (const group of chunk(uids, 100)) {
    const refs = group.map((u) => db.doc(`users/${u}`));
    const snaps = await db.getAll(...refs);
    for (const s of snaps) {
      if (!s.exists) continue;
      const t = s.data()!.fcmTokens as string[] | undefined;
      if (t && t.length > 0) tokens.push(...t);
    }
  }
  return tokens;
}

function truncate(s: string, n: number): string {
  return s.length > n ? `${s.substring(0, n)}…` : s;
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}
