import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Validates that a chat room can be created:
 * - Caller must be a player
 * - All participants must be players with e2ePublicKey set
 */
export const validateChatRoom = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const { participantUids } = request.data;

  if (!participantUids || !Array.isArray(participantUids)) {
    throw new HttpsError("invalid-argument", "participantUids required.");
  }

  // Verify caller is a player
  const callerSnap = await admin.firestore().doc(`users/${uid}`).get();
  if (!callerSnap.exists || callerSnap.data()?.role !== "player") {
    throw new HttpsError(
      "permission-denied",
      "Only players can create chats."
    );
  }

  // Verify all participants are players with e2ePublicKey
  const publicKeys: Record<string, string> = {};

  for (const pUid of participantUids as string[]) {
    const userSnap = await admin.firestore().doc(`users/${pUid}`).get();
    if (!userSnap.exists) {
      throw new HttpsError("not-found", `User ${pUid} not found.`);
    }
    const userData = userSnap.data()!;
    if (userData.role !== "player") {
      throw new HttpsError(
        "invalid-argument",
        `User ${pUid} is not a player.`
      );
    }
    if (!userData.e2ePublicKey) {
      throw new HttpsError(
        "failed-precondition",
        `User ${pUid} has not set up encryption.`
      );
    }
    publicKeys[pUid] = userData.e2ePublicKey;
  }

  return { valid: true, publicKeys };
});
