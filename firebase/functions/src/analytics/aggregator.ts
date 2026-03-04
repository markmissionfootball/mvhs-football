import * as admin from "firebase-admin";

/**
 * Nightly aggregation function that rolls up agent usage sessions into daily metrics.
 * Runs at 2:00 AM PT to process the previous day's activity.
 *
 * Writes to: analytics/daily/{date} collection
 */
export async function aggregateDailyMetrics(): Promise<void> {
  const db = admin.firestore();

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);

  const endOfYesterday = new Date(yesterday.getTime() + 86400000);
  const dateKey = yesterday.toISOString().split("T")[0]; // "2026-03-02"

  // 1. Count agent sessions from yesterday
  // Agent sessions are logged in agentSessions collection when agentChat is called
  const sessionsSnap = await db
    .collection("agentSessions")
    .where("createdAt", ">=", yesterday)
    .where("createdAt", "<", endOfYesterday)
    .get();

  const totalSessions = sessionsSnap.size;
  const uniquePlayers = new Set<string>();
  let totalToolCalls = 0;
  const toolUsage: Record<string, number> = {};

  for (const doc of sessionsSnap.docs) {
    const session = doc.data();
    uniquePlayers.add(session.playerId);

    if (session.toolsUsed) {
      for (const tool of session.toolsUsed as string[]) {
        totalToolCalls++;
        toolUsage[tool] = (toolUsage[tool] ?? 0) + 1;
      }
    }
  }

  // 2. Count active users (any app open event)
  const activeUsersSnap = await db
    .collection("appEvents")
    .where("type", "==", "app_open")
    .where("timestamp", ">=", yesterday)
    .where("timestamp", "<", endOfYesterday)
    .get();

  const activeUsers = new Set(
    activeUsersSnap.docs.map((doc) => doc.data().uid)
  ).size;

  // 3. Write daily metrics
  await db
    .collection("analytics")
    .doc("daily")
    .collection("dates")
    .doc(dateKey)
    .set({
      date: dateKey,
      activeUsers,
      agentSessions: totalSessions,
      uniqueAgentUsers: uniquePlayers.size,
      totalToolCalls,
      toolUsage,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  console.log(
    `Analytics for ${dateKey}: ${activeUsers} active users, ${totalSessions} agent sessions, ${uniquePlayers.size} unique agent users`
  );
}
