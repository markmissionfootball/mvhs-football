import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

import { logAudit } from "./audit";

/**
 * Mute/unmute oversight. A `mutes/{uid}` doc existing means the user is blocked
 * from posting replies (enforced in firestore.rules). This trigger records the
 * action in the audit log either way.
 */
export const onMuteWritten = onDocumentWritten(
  "mutes/{uid}",
  async (event) => {
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;
    const uid = event.params.uid;
    const db = admin.firestore();

    if (!existedBefore && existsAfter) {
      const d = event.data!.after.data()!;
      await logAudit(db, {
        type: "user_muted",
        actorUid: d.mutedBy ?? "unknown",
        actorName: "Admin",
        targetUid: uid,
        meta: { reason: d.reason ?? null },
      });
    } else if (existedBefore && !existsAfter) {
      await logAudit(db, {
        type: "user_unmuted",
        actorUid: "admin",
        actorName: "Admin",
        targetUid: uid,
        meta: {},
      });
    }
  }
);
