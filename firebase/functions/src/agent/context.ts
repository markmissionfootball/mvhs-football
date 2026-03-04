import * as admin from "firebase-admin";

export interface PlayerContext {
  player: admin.firestore.DocumentData;
  preferences: admin.firestore.DocumentData | null;
  recentMaxes: admin.firestore.DocumentData | null;
  recruitingProfile: admin.firestore.DocumentData | null;
}

/**
 * Assembles the full player context from Firestore for the Claude agent.
 * This data is injected into the system prompt so the agent knows who it's talking to.
 */
export async function assemblePlayerContext(
  playerId: string
): Promise<PlayerContext> {
  const db = admin.firestore();

  const [playerSnap, prefsSnap, maxesSnap, recruitingSnap] = await Promise.all([
    db.collection("players").doc(playerId).get(),
    db.collection("playerPreferences").doc(playerId).get(),
    db
      .collection("players")
      .doc(playerId)
      .collection("maxEntries")
      .orderBy("testDate", "desc")
      .limit(1)
      .get(),
    db.collection("recruitingProfiles").doc(playerId).get(),
  ]);

  if (!playerSnap.exists) {
    throw new Error(`Player ${playerId} not found`);
  }

  return {
    player: playerSnap.data()!,
    preferences: prefsSnap.exists ? prefsSnap.data()! : null,
    recentMaxes:
      maxesSnap.docs.length > 0 ? maxesSnap.docs[0].data() : null,
    recruitingProfile: recruitingSnap.exists ? recruitingSnap.data()! : null,
  };
}
