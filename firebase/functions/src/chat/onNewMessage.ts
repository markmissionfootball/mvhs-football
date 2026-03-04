import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Firestore trigger: sends FCM push notifications when a new encrypted
 * message is written to a chat room. Since messages are E2E encrypted,
 * the notification body is generic ("Sent you a message").
 */
export const onNewChatMessage = onDocumentCreated(
  "chatRooms/{roomId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    const roomId = event.params.roomId;
    const senderUid = messageData.senderUid as string;
    const senderName = messageData.senderName as string;

    // Get the chat room to find all participants
    const roomSnap = await admin
      .firestore()
      .doc(`chatRooms/${roomId}`)
      .get();

    if (!roomSnap.exists) return;
    const room = roomSnap.data()!;

    // Get FCM tokens for all participants EXCEPT the sender
    const recipientUids = (room.participantUids as string[]).filter(
      (uid: string) => uid !== senderUid
    );

    const tokens: string[] = [];
    for (const uid of recipientUids) {
      const userSnap = await admin.firestore().doc(`users/${uid}`).get();
      if (userSnap.exists) {
        const userData = userSnap.data()!;
        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          tokens.push(...userData.fcmTokens);
        }
      }
    }

    if (tokens.length === 0) return;

    const title =
      room.type === "dm"
        ? senderName
        : `${senderName} in ${room.name || "Group Chat"}`;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body: "Sent you a message",
      },
      data: {
        type: "chat_message",
        roomId,
        senderUid,
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    // Update room's lastMessageAt for ordering
    await admin.firestore().doc(`chatRooms/${roomId}`).update({
      lastMessageAt: messageData.sentAt,
    });
  }
);
