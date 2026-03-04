import * as admin from "firebase-admin";

/**
 * Sends scheduled daily notifications:
 * - Workout reminders for players with workouts today
 * - Game day alerts (3 hours before game time)
 * - Coach announcement broadcasts
 *
 * Called by the dailyNotifications scheduled function at 7:00 AM PT.
 */
export async function sendScheduledNotifications(): Promise<void> {
  const db = admin.firestore();
  const messaging = admin.messaging();

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today.getTime() + 86400000);

  // 1. Check for games today
  const gamesSnap = await db
    .collection("games")
    .where("dateTime", ">=", today)
    .where("dateTime", "<", tomorrow)
    .get();

  for (const gameDoc of gamesSnap.docs) {
    const game = gameDoc.data();
    const level = game.level as string;

    // Get all active players on this level
    const playersSnap = await db
      .collection("players")
      .where("team", "==", level)
      .where("active", "==", true)
      .get();

    const playerIds = playersSnap.docs.map((doc) => doc.id);

    // Get FCM tokens for these players' user accounts
    const tokens = await getTokensForPlayers(playerIds);

    if (tokens.length > 0) {
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "GAME DAY",
          body: `${game.opponent} — ${game.location ?? "TBD"} | ${game.isHome ? "HOME" : "AWAY"}`,
        },
        data: {
          type: "game_day",
          gameId: gameDoc.id,
        },
      });
    }
  }

  // 2. Check for unread announcements from today
  const announcementsSnap = await db
    .collection("announcements")
    .where("createdAt", ">=", today)
    .where("createdAt", "<", tomorrow)
    .get();

  for (const announcementDoc of announcementsSnap.docs) {
    const announcement = announcementDoc.data();

    // Get tokens based on audience level
    const tokens = await getTokensByAudience(announcement.audienceLevel);

    if (tokens.length > 0) {
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: announcement.title,
          body:
            announcement.body.length > 100
              ? announcement.body.substring(0, 100) + "..."
              : announcement.body,
        },
        data: {
          type: "announcement",
          announcementId: announcementDoc.id,
        },
      });
    }
  }

  console.log(
    `Notifications sent: ${gamesSnap.size} game alerts, ${announcementsSnap.size} announcements`
  );
}

async function getTokensForPlayers(playerIds: string[]): Promise<string[]> {
  if (playerIds.length === 0) return [];

  const db = admin.firestore();
  const tokens: string[] = [];

  // Batch lookup user accounts linked to these players
  for (const playerId of playerIds) {
    const usersSnap = await db
      .collection("users")
      .where("linkedPlayerId", "==", playerId)
      .limit(1)
      .get();

    if (!usersSnap.empty) {
      const user = usersSnap.docs[0].data();
      if (user.fcmTokens && user.fcmTokens.length > 0) {
        tokens.push(...user.fcmTokens);
      }
    }
  }

  return tokens;
}

async function getTokensByAudience(audienceLevel: string): Promise<string[]> {
  const db = admin.firestore();
  const tokens: string[] = [];

  let query: admin.firestore.Query = db.collection("users");

  if (audienceLevel !== "all") {
    // e.g., "varsity", "jv", "freshman"
    // Get players on that team, then get their user tokens
    const playersSnap = await db
      .collection("players")
      .where("team", "==", audienceLevel)
      .where("active", "==", true)
      .get();

    const playerIds = playersSnap.docs.map((doc) => doc.id);
    return getTokensForPlayers(playerIds);
  }

  // "all" audience — send to everyone with tokens
  const usersSnap = await query.get();
  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    if (user.fcmTokens && user.fcmTokens.length > 0) {
      tokens.push(...user.fcmTokens);
    }
  }

  return tokens;
}
