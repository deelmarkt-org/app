/**
 * Carrier Tracking Webhook Edge Function (B-33)
 *
 * Receives PostNL/DHL tracking events and updates transaction status.
 * When a 'delivered' event is received, the DB trigger automatically:
 * 1. Sets transaction.status = 'delivered'
 * 2. Sets escrow_deadline = now() + 48h (via trg_set_escrow_deadline)
 * 3. release-escrow cron handles payout (B-21/B-22/B-23)
 *
 * verify_jwt = false — carrier sends no JWT. Security via HMAC.
 * Idempotency: Upstash Redis NX (primary) + DB UNIQUE (safety net).
 *
 * Reference: docs/epics/E05-shipping-logistics.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { jsonResponse } from "../_shared/response.ts";
import {
  getRedisCredentials,
  checkIdempotency,
  rollbackIdempotency,
} from "../_shared/redis.ts";

// ---------------------------------------------------------------------------
// Zod input validation (§9)
// ---------------------------------------------------------------------------

const TrackingEventSchema = z.object({
  barcode: z.string().min(1, "Barcode is required"),
  status: z.string().min(1, "Status is required"),
  description: z.string().optional(),
  location: z.string().optional(),
  occurred_at: z.string().datetime({ message: "Invalid datetime" }),
  event_id: z.string().min(1, "Event ID is required"),
  carrier: z.enum(["postnl", "dhl"]),
});

// ---------------------------------------------------------------------------
// HMAC verification — uses crypto.subtle.verify (M5: inherently timing-safe)
// ---------------------------------------------------------------------------

async function verifyCarrierSignature(
  body: string,
  signature: string | null,
  secret: string
): Promise<boolean> {
  if (!signature) return false;

  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"]
    );

    const sigBytes = new Uint8Array(
      (signature.match(/.{2}/g) ?? []).map((h) => parseInt(h, 16))
    );

    return await crypto.subtle.verify(
      "HMAC",
      key,
      sigBytes,
      encoder.encode(body)
    );
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // H3: Explicit env var guards — no non-null assertions
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("[tracking-webhook] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Internal configuration error" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // H2: Rate limiting is handled by Cloudflare edge layer (WAF rules B-02).
  // Edge Functions don't implement app-level rate limiting — Cloudflare
  // drops abusive IPs before requests reach Supabase.

  // Hoisted for Redis key rollback in catch block (C1)
  let redisCreds: ReturnType<typeof getRedisCredentials> | null = null;
  let idempotencyKey = "";

  try {
    // 1. Read and validate body
    const rawBody = await req.text();
    const payload = TrackingEventSchema.parse(JSON.parse(rawBody));

    // 2. Verify carrier HMAC signature (H4: distinct vault error handling)
    const secretName = payload.carrier === "postnl"
        ? "postnl_webhook_secret"
        : "dhl_webhook_secret";

    let webhookSecret: string;
    try {
      webhookSecret = await getVaultSecret(supabase, secretName);
    } catch (err) {
      console.error(`[tracking-webhook] Vault secret '${secretName}' not configured: ${(err as Error).message}`);
      return jsonResponse({ error: "Webhook signature verification unavailable" }, 503);
    }

    const signature = req.headers.get("x-carrier-signature");
    const isValid = await verifyCarrierSignature(rawBody, signature, webhookSecret);
    if (!isValid) {
      console.error(`[tracking-webhook] Invalid ${payload.carrier} signature for ${payload.barcode}`);
      return jsonResponse({ error: "Invalid signature" }, 401);
    }

    // 3. C1: Redis NX idempotency check (§9 mandatory, R-11: shared redis.ts)
    redisCreds = getRedisCredentials();
    idempotencyKey = `tracking:webhook:${payload.event_id}`;
    const isNew = await checkIdempotency(redisCreds, idempotencyKey);
    if (!isNew) {
      console.log(`[tracking-webhook] Duplicate skipped (Redis): ${payload.event_id}`);
      return new Response("Already processed", { status: 200 });
    }

    // 4. Lookup shipping label by barcode
    const { data: label, error: labelError } = await supabase
      .from("shipping_labels")
      .select("id, transaction_id")
      .eq("barcode", payload.barcode)
      .single();

    if (labelError || !label) {
      console.error(`[tracking-webhook] Barcode not found: ${payload.barcode}`);
      return jsonResponse({ error: "Barcode not found" }, 422);
    }

    // 5. Insert tracking event (DB UNIQUE on carrier_event_id is safety net)
    const { error: insertError } = await supabase
      .from("tracking_events")
      .insert({
        shipping_label_id: label.id,
        transaction_id: label.transaction_id,
        carrier_event_id: payload.event_id,
        status: payload.status,
        description: payload.description ?? null,
        location: payload.location ?? null,
        occurred_at: payload.occurred_at,
      });

    if (insertError?.code === "23505") {
      console.log(`[tracking-webhook] Duplicate skipped (DB): ${payload.event_id}`);
      return new Response("Already processed", { status: 200 });
    }
    if (insertError) {
      throw new Error(`Failed to insert tracking event: ${insertError.message}`);
    }

    // 6. DB trigger (trg_on_tracking_delivered) handles status transition
    //    when status = 'delivered'. No manual update needed here.

    console.log(
      `[tracking-webhook] ${payload.carrier} ${payload.status} for barcode ${payload.barcode} (txn: ${label.transaction_id})`
    );

    return jsonResponse({
      status: "ok",
      event_id: payload.event_id,
      transaction_id: label.transaction_id,
    }, 200);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return jsonResponse({
        error: `Validation: ${error.errors.map((e) => e.message).join(", ")}`,
      }, 400);
    }

    // C1: Rollback Redis idempotency key on failure so carrier retry succeeds.
    // Without this, a failed event is "consumed" for 24h and never processed.
    if (redisCreds && idempotencyKey) {
      await rollbackIdempotency(redisCreds, idempotencyKey);
    }

    console.error(`[tracking-webhook] Error: ${(error as Error).message}`);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});
