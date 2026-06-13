import * as admin from "firebase-admin";

/**
 * Multi-channel delivery for broadcasts.
 *
 * Compliance note — "platform sending": email and SMS are dispatched from the
 * PLATFORM's own sender identity (a shared from-address / phone number), never
 * a coach's personal contact info. That removes the direct coach↔student
 * channel that schools are trying to eliminate, while still reaching families.
 *
 * Push is fully implemented against FCM. Email and SMS are written against a
 * provider-agnostic interface with a console fallback, so dropping in SendGrid
 * (email) and Twilio (SMS) is a credentials-and-one-function change with no
 * call-site edits. Configure via environment:
 *   EMAIL_PROVIDER=sendgrid  SENDGRID_API_KEY=...  BROADCAST_FROM_EMAIL=...
 *   SMS_PROVIDER=twilio      TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=...
 *                            BROADCAST_FROM_NUMBER=...
 */

export interface DeliveryResult {
  sent: number;
  failed: number;
}

export interface Recipient {
  uid: string;
  displayName: string;
  email?: string | null;
  phoneNumber?: string | null;
  phoneVerified?: boolean;
  fcmTokens?: string[];
}

const merge = (a: DeliveryResult, b: DeliveryResult): DeliveryResult => ({
  sent: a.sent + b.sent,
  failed: a.failed + b.failed,
});

// ── Push (FCM) ──────────────────────────────────────────────
export async function sendPush(
  recipients: Recipient[],
  title: string,
  body: string,
  broadcastId: string,
  priority: string
): Promise<DeliveryResult> {
  const tokens: string[] = [];
  for (const r of recipients) {
    if (r.fcmTokens && r.fcmTokens.length > 0) tokens.push(...r.fcmTokens);
  }
  if (tokens.length === 0) return { sent: 0, failed: 0 };

  let sent = 0;
  let failed = 0;
  // sendEachForMulticast caps at 500 tokens per call.
  for (const batch of chunk(tokens, 500)) {
    const res = await admin.messaging().sendEachForMulticast({
      tokens: batch,
      notification: { title, body },
      data: { type: "broadcast", broadcastId },
      android: { priority: priority === "urgent" ? "high" : "normal" },
      apns: { payload: { aps: { sound: "default" } } },
    });
    sent += res.successCount;
    failed += res.failureCount;
  }
  return { sent, failed };
}

// ── Email ───────────────────────────────────────────────────
export async function sendEmail(
  recipients: Recipient[],
  subject: string,
  body: string
): Promise<DeliveryResult> {
  const targets = recipients.filter((r) => !!r.email);
  if (targets.length === 0) return { sent: 0, failed: 0 };

  const provider = process.env.EMAIL_PROVIDER ?? "console";
  if (provider === "sendgrid" && process.env.SENDGRID_API_KEY) {
    return sendEmailViaSendgrid(targets, subject, body);
  }

  // Fallback: log only. Treated as "queued" so the UI flow is exercised in dev.
  console.log(
    `[email:console] would send "${subject}" to ${targets.length} recipients ` +
      `from ${process.env.BROADCAST_FROM_EMAIL ?? "no-reply@platform"}`
  );
  return { sent: targets.length, failed: 0 };
}

async function sendEmailViaSendgrid(
  targets: Recipient[],
  subject: string,
  body: string
): Promise<DeliveryResult> {
  const from = process.env.BROADCAST_FROM_EMAIL ?? "no-reply@platform.app";
  let sent = 0;
  let failed = 0;
  for (const batch of chunk(targets, 900)) {
    try {
      const resp = await fetch("https://api.sendgrid.com/v3/mail/send", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.SENDGRID_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          // Individual personalizations keep recipients hidden from each other.
          personalizations: batch.map((r) => ({ to: [{ email: r.email }] })),
          from: { email: from },
          subject,
          content: [{ type: "text/plain", value: body }],
        }),
      });
      if (resp.ok) sent += batch.length;
      else failed += batch.length;
    } catch (e) {
      console.error("[email:sendgrid] batch failed", e);
      failed += batch.length;
    }
  }
  return { sent, failed };
}

// ── SMS ─────────────────────────────────────────────────────
export async function sendSms(
  recipients: Recipient[],
  body: string,
  broadcastId: string
): Promise<DeliveryResult> {
  const targets = recipients.filter((r) => !!r.phoneNumber);
  if (targets.length === 0) return { sent: 0, failed: 0 };

  const provider = process.env.SMS_PROVIDER ?? "console";
  if (
    provider === "twilio" &&
    process.env.TWILIO_ACCOUNT_SID &&
    process.env.TWILIO_AUTH_TOKEN
  ) {
    return sendSmsViaTwilio(targets, body);
  }

  console.log(
    `[sms:console] would send broadcast ${broadcastId} to ${targets.length} ` +
      `numbers from ${process.env.BROADCAST_FROM_NUMBER ?? "platform-number"}`
  );
  return { sent: targets.length, failed: 0 };
}

async function sendSmsViaTwilio(
  targets: Recipient[],
  body: string
): Promise<DeliveryResult> {
  const sid = process.env.TWILIO_ACCOUNT_SID!;
  const token = process.env.TWILIO_AUTH_TOKEN!;
  const from = process.env.BROADCAST_FROM_NUMBER!;
  const auth = Buffer.from(`${sid}:${token}`).toString("base64");
  const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;

  let sent = 0;
  let failed = 0;
  // Twilio has no native multicast; send per-recipient with bounded concurrency.
  for (const batch of chunk(targets, 20)) {
    const results = await Promise.all(
      batch.map(async (r) => {
        try {
          const params = new URLSearchParams({
            To: r.phoneNumber!,
            From: from,
            Body: body,
          });
          const resp = await fetch(url, {
            method: "POST",
            headers: {
              Authorization: `Basic ${auth}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: params.toString(),
          });
          return resp.ok;
        } catch (e) {
          console.error("[sms:twilio] send failed", e);
          return false;
        }
      })
    );
    sent += results.filter(Boolean).length;
    failed += results.filter((r) => !r).length;
  }
  return { sent, failed };
}

/** Dispatches across all requested channels and returns per-channel results. */
export async function dispatch(
  channels: string[],
  recipients: Recipient[],
  opts: {
    title: string;
    subject: string;
    body: string;
    broadcastId: string;
    priority: string;
  }
): Promise<Record<string, DeliveryResult>> {
  const out: Record<string, DeliveryResult> = {};
  if (channels.includes("push")) {
    out.push = await sendPush(
      recipients,
      opts.title,
      opts.body,
      opts.broadcastId,
      opts.priority
    );
  }
  if (channels.includes("email")) {
    out.email = await sendEmail(recipients, opts.subject, opts.body);
  }
  if (channels.includes("sms")) {
    out.sms = await sendSms(recipients, opts.body, opts.broadcastId);
  }
  return out;
}

export function totalDelivery(
  byChannel: Record<string, DeliveryResult>
): DeliveryResult {
  return Object.values(byChannel).reduce(merge, { sent: 0, failed: 0 });
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}
