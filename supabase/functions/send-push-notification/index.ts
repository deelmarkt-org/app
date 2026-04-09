/**
 * Send Push Notification Edge Function (R-34)
 *
 * verify_jwt = false — triggered by database webhook (pg_net).
 * Auth via service_role check.
 *
 * Flow:
 *   1. Idempotency check (Redis NX) to prevent duplicate pushes on pg_net retry.
 *   2. Resolve the recipient — the conversation participant who is NOT the sender.
 *   3. Check notification_preferences.messages — skip if disabled.
 *   4. Fetch recipient's FCM device tokens from device_tokens table.
 *   5. Send push via FCM HTTP v1 API using Google service account from Vault.
 *   6. Clean up stale tokens (FCM returns UNREGISTERED for expired tokens).
 *
 * Reference: docs/epics/E04-messaging.md §Push notifications
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { checkIdempotency } from "../_shared/idempotency.ts";
import { getRedisCredentials } from "../_shared/redis.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MessagePayload {
  message_id: string;
  conversation_id: string;
  sender_id: string;
  text: string;
  type: string;
}

interface FcmTokenRow {
  id: string;
  token: string;
  platform: string;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

// ---------------------------------------------------------------------------
// Google OAuth2 — get access token for FCM v1 API
// ---------------------------------------------------------------------------

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = btoa(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const signingInput = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${arrayBufferToBase64Url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!res.ok) {
    throw new Error(`Google OAuth2 failed: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer { // pragma: allowlist secret
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "") // pragma: allowlist secret
    .replace(/-----END PRIVATE KEY-----/, "") // pragma: allowlist secret
    .replace(/\n/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// ---------------------------------------------------------------------------
// FCM send — parallel for multi-device
// ---------------------------------------------------------------------------

interface FcmResult {
  token: string;
  success: boolean;
  unregistered: boolean;
}

async function sendFcmMessages(
  accessToken: string,
  projectId: string,
  tokens: FcmTokenRow[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<FcmResult[]> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  return Promise.all(
    tokens.map(async (t): Promise<FcmResult> => {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: { title, body },
            data,
            android: { priority: "high" },
            apns: {
              payload: { aps: { sound: "default", badge: 1 } },
            },
          },
        }),
      });

      const responseBody = await res.text();
      const unregistered = !res.ok && responseBody.includes("UNREGISTERED");

      if (!res.ok && !unregistered) {
        console.error(
          `[push] FCM send failed for token ${t.token.slice(0, 8)}...: ${res.status} ${responseBody}`,
        );
      }

      return { token: t.token, success: res.ok, unregistered };
    }),
  );
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let payload: MessagePayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { message_id, conversation_id, sender_id, text, type } = payload;

  if (!conversation_id || !sender_id) {
    return jsonResponse({ error: "Missing conversation_id or sender_id" }, 400);
  }

  try {
    // 0. Idempotency — prevent duplicate pushes on pg_net retry.
    const redis = getRedisCredentials();
    const isNew = await checkIdempotency(redis, `push:${message_id}`, 300);
    if (!isNew) {
      return jsonResponse({ status: "skipped", reason: "duplicate" });
    }

    // 1. Resolve recipient — the participant who is NOT the sender.
    const { data: conv, error: convError } = await supabase
      .from("conversations")
      .select("buyer_id, listings!inner(seller_id, title)")
      .eq("id", conversation_id)
      .single();

    if (convError || !conv) {
      console.error(`[push] conversation lookup failed: ${convError?.message}`);
      return jsonResponse({ status: "skipped", reason: "conversation_not_found" });
    }

    const typedConv = conv as {
      buyer_id: string;
      listings: { seller_id: string; title: string };
    };
    const recipientId =
      sender_id === typedConv.buyer_id
        ? typedConv.listings.seller_id
        : typedConv.buyer_id;

    // 2. Check notification preferences.
    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("messages")
      .eq("user_id", recipientId)
      .maybeSingle();

    if (prefs && prefs.messages === false) {
      return jsonResponse({ status: "skipped", reason: "notifications_disabled" });
    }

    // 3. Fetch device tokens.
    const { data: tokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("id, token, platform")
      .eq("user_id", recipientId);

    if (tokenError) {
      console.error(`[push] token lookup failed: ${tokenError.message}`);
      return jsonResponse({ status: "error", message: tokenError.message }, 500);
    }

    if (!tokens || tokens.length === 0) {
      return jsonResponse({ status: "skipped", reason: "no_device_tokens" });
    }

    // 4. Get FCM credentials from Vault (parse once).
    const sa: ServiceAccount = JSON.parse(
      await getVaultSecret(supabase, "fcm_service_account"),
    );
    const accessToken = await getFcmAccessToken(sa);

    // 5. Build notification content.
    const { data: senderProfile } = await supabase
      .from("user_profiles")
      .select("display_name")
      .eq("id", sender_id)
      .single();

    const senderName = (senderProfile as { display_name: string })?.display_name ?? "Someone";
    const title = type === "offer"
      ? `${senderName} sent an offer`
      : `${senderName} sent a message`;
    const body = text.length > 100 ? `${text.slice(0, 97)}...` : text;

    // 6. Send FCM messages (parallel for multi-device).
    const results = await sendFcmMessages(
      accessToken,
      sa.project_id,
      tokens as FcmTokenRow[],
      title,
      body,
      { conversation_id, type },
    );

    // 7. Clean up stale tokens.
    const staleTokenIds = results
      .filter((r) => r.unregistered)
      .map((r) => {
        const match = (tokens as FcmTokenRow[]).find((t) => t.token === r.token);
        return match?.id;
      })
      .filter(Boolean) as string[];

    if (staleTokenIds.length > 0) {
      await supabase.from("device_tokens").delete().in("id", staleTokenIds);
      console.log(`[push] cleaned ${staleTokenIds.length} stale token(s)`);
    }

    const sent = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success && !r.unregistered).length;

    console.log(
      `[push] recipient=${recipientId.slice(0, 8)} sent=${sent} failed=${failed} stale=${staleTokenIds.length}`,
    );

    return jsonResponse({
      status: "ok",
      sent,
      failed,
      stale_cleaned: staleTokenIds.length,
    });
  } catch (error) {
    const message = (error as Error).message;
    console.error(`[push] error: ${message}`);
    return jsonResponse({ status: "error", message }, 500);
  }
});
