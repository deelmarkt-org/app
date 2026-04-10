/**
 * Send Sanction Notification Edge Function (R-37)
 *
 * verify_jwt = false — triggered by database webhook (pg_net) on
 * account_sanctions INSERT. Auth via service_role check.
 *
 * Flow:
 *   1. Validate payload (Zod).
 *   2. Idempotency check (Redis NX, keyed by sanction_id) — prevents duplicate
 *      pushes on pg_net retry.
 *   3. Fetch user's FCM device tokens from device_tokens.
 *   4. Build push title/body per sanction type (warning / suspension / ban).
 *      Note: notification_preferences are NOT checked — sanctions are mandatory
 *      legal communications, not opt-out push notifications.
 *   5. Send push via FCM HTTP v1 API using Google service account from Vault.
 *   6. Clean up stale tokens (FCM UNREGISTERED).
 *
 * Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
 * Reference: docs/SPRINT-PLAN.md R-37
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { checkIdempotency } from "../_shared/idempotency.ts";
import { getRedisCredentials } from "../_shared/redis.ts";

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

const SanctionPayloadSchema = z.object({
  event: z.literal("account_sanctioned"),
  sanction_id: z.string().uuid(),
  user_id: z.string().uuid(),
  type: z.enum(["warning", "suspension", "ban"]),
  reason: z.string().min(1),
  expires_at: z.string().nullable().optional(),
});

type SanctionPayload = z.infer<typeof SanctionPayloadSchema>;

// ---------------------------------------------------------------------------
// FCM helpers (shared with send-push-notification)
// ---------------------------------------------------------------------------

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

interface FcmResult {
  token: string;
  success: boolean;
  unregistered: boolean;
}

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
    body:
      `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
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

async function sendFcmMessages(
  accessToken: string,
  projectId: string,
  tokens: FcmTokenRow[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<FcmResult[]> {
  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  return await Promise.all(
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
          `[sanction-push] FCM send failed for token ${
            t.token.slice(0, 8)
          }...: ${res.status} ${responseBody}`,
        );
      }

      return { token: t.token, success: res.ok, unregistered };
    }),
  );
}

// ---------------------------------------------------------------------------
// Notification copy per sanction type
// ---------------------------------------------------------------------------

function buildPushContent(payload: SanctionPayload): {
  title: string;
  body: string;
} {
  switch (payload.type) {
    case "warning":
      return {
        title: "Account warning",
        body: `Your account has received a warning: ${payload.reason}`,
      };
    case "suspension": {
      const until = payload.expires_at
        ? ` until ${new Date(payload.expires_at).toLocaleDateString("nl-NL")}`
        : "";
      return {
        title: "Account suspended",
        body:
          `Your account has been suspended${until}. Reason: ${payload.reason}`,
      };
    }
    case "ban":
      return {
        title: "Account banned",
        body:
          `Your account has been permanently banned. Reason: ${payload.reason}`,
      };
  }
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

  let rawBody: unknown;
  try {
    rawBody = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = SanctionPayloadSchema.safeParse(rawBody);
  if (!parsed.success) {
    return jsonResponse({ error: parsed.error.flatten() }, 400);
  }

  const payload = parsed.data;

  try {
    // 1. Idempotency — prevent duplicate pushes on pg_net retry.
    const redis = getRedisCredentials();
    const isNew = await checkIdempotency(
      redis,
      `push:sanction:${payload.sanction_id}`,
      300,
    );
    if (!isNew) {
      return jsonResponse({ status: "skipped", reason: "duplicate" });
    }

    // 2. Fetch device tokens (no prefs check — sanctions are mandatory comms).
    const { data: tokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("id, token, platform")
      .eq("user_id", payload.user_id);

    if (tokenError) {
      console.error(
        `[sanction-push] token lookup failed: ${tokenError.message}`,
      );
      return jsonResponse(
        { status: "error", message: tokenError.message },
        500,
      );
    }

    if (!tokens || tokens.length === 0) {
      return jsonResponse({ status: "skipped", reason: "no_device_tokens" });
    }

    // 3. Get FCM credentials from Vault.
    const sa: ServiceAccount = JSON.parse(
      await getVaultSecret(supabase, "fcm_service_account"),
    );
    const accessToken = await getFcmAccessToken(sa);

    // 4. Build notification content.
    const { title, body } = buildPushContent(payload);

    // 5. Send FCM messages (parallel for multi-device).
    const results = await sendFcmMessages(
      accessToken,
      sa.project_id,
      tokens as FcmTokenRow[],
      title,
      body,
      {
        event: payload.event,
        sanction_id: payload.sanction_id,
        type: payload.type,
      },
    );

    // 6. Clean up stale tokens.
    const staleTokenIds = results
      .filter((r) => r.unregistered)
      .map((r) => {
        const match = (tokens as FcmTokenRow[]).find((t) =>
          t.token === r.token
        );
        return match?.id;
      })
      .filter(Boolean) as string[];

    if (staleTokenIds.length > 0) {
      await supabase.from("device_tokens").delete().in("id", staleTokenIds);
      console.log(
        `[sanction-push] cleaned ${staleTokenIds.length} stale token(s)`,
      );
    }

    const sent = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success && !r.unregistered).length;

    console.log(
      `[sanction-push] user=${
        payload.user_id.slice(0, 8)
      } type=${payload.type} sent=${sent} failed=${failed} stale=${staleTokenIds.length}`,
    );

    return jsonResponse({
      status: "ok",
      sent,
      failed,
      stale_cleaned: staleTokenIds.length,
    });
  } catch (error) {
    const message = (error as Error).message;
    console.error(`[sanction-push] error: ${message}`);
    return jsonResponse({ status: "error", message }, 500);
  }
});
