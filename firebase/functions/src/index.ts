import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { handleAgentMessage } from "./agent/handler";
import { sendScheduledNotifications } from "./notifications/scheduler";
import { aggregateDailyMetrics } from "./analytics/aggregator";
import { onNewChatMessage } from "./chat/onNewMessage";
import { validateChatRoom } from "./chat/validateChatRoom";

admin.initializeApp();

// ─── Agent endpoint ─────────────────────────────────────────
// Called from the Flutter app when a player sends a message to the AI agent.
// Receives: { playerId, message, conversationHistory }
// Returns:  { response, toolResults? }
export const agentChat = onCall(async (request) => {
  const { playerId, message, conversationHistory } = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Must be signed in to use the agent."
    );
  }

  if (!playerId || !message) {
    throw new HttpsError(
      "invalid-argument",
      "playerId and message are required."
    );
  }

  const response = await handleAgentMessage({
    playerId,
    uid,
    message,
    conversationHistory: conversationHistory ?? [],
  });

  return response;
});

// ─── Scheduled notifications ────────────────────────────────
// Runs daily at 7:00 AM PT to send workout reminders, game-day alerts, etc.
export const dailyNotifications = onSchedule(
  { schedule: "0 7 * * *", timeZone: "America/Los_Angeles" },
  async () => {
    await sendScheduledNotifications();
  }
);

// ─── Nightly analytics aggregation ─────────────────────────
// Runs nightly at 2:00 AM PT to roll up agent sessions into daily metrics.
export const nightlyAnalytics = onSchedule(
  { schedule: "0 2 * * *", timeZone: "America/Los_Angeles" },
  async () => {
    await aggregateDailyMetrics();
  }
);

// ─── Player Chat ────────────────────────────────────────────
// Firestore trigger: push notification on new encrypted message
export { onNewChatMessage };

// Callable: validates participants before chat room creation
export { validateChatRoom };
