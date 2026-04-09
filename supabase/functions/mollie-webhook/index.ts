/**
 * Mollie Webhook Edge Function
 *
 * B-15: Webhook idempotency via Upstash Redis NX
 * B-16: HMAC-SHA256 signature verification
 *
 * verify_jwt = false — Mollie sends no JWT. Security via HMAC + Redis.
 * DLQ retries authenticate via service_role JWT (C2 fix).
 *
 * Reference: docs/epics/E03-payments-escrow.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";
import { getRedisCredentials } from "../_shared/redis.ts";
import { checkIdempotency, rollbackIdempotency } from "../_shared/idempotency.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MolliePayment {
  id: string;
  status: string;
  amount: { value: string; currency: string };
  metadata?: { transaction_id?: string };
}

// ---------------------------------------------------------------------------
// Zod input validation (§9)
// ---------------------------------------------------------------------------

const WebhookPayloadSchema = z.object({
  id: z.string().min(1, "Payment ID is required").max(50),
});

// ---------------------------------------------------------------------------
// HMAC-SHA256 signature verification (B-16)
// ---------------------------------------------------------------------------

async function verifySignature(
  body: string,
  signature: string | null,
  secret: string
): Promise<boolean> {
  if (!signature) return false;

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
  const computed = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Constant-time comparison to prevent timing attacks
  if (computed.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < computed.length; i++) {
    mismatch |= computed.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

// ---------------------------------------------------------------------------
// Mollie API client
// ---------------------------------------------------------------------------

async function fetchMolliePayment(
  paymentId: string,
  apiKey: string
): Promise<MolliePayment> {
  const response = await fetch(
    `https://api.mollie.com/v2/payments/${paymentId}`,
    { headers: { Authorization: `Bearer ${apiKey}` } }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Mollie API error (${response.status}): ${text}`);
  }

  return response.json();
}

// ---------------------------------------------------------------------------
// Transaction status mapping
// ---------------------------------------------------------------------------

function mapMollieStatus(mollieStatus: string): string | null {
  switch (mollieStatus) {
    case "paid":
      return "paid";
    case "expired":
      return "expired";
    case "failed":
      return "failed";
    case "canceled":
      return "cancelled";
    default:
      // open, pending, authorized — transient states, no change needed
      return null;
  }
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("[mollie-webhook] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Internal configuration error" }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // Hoisted for catch-block rollback — req.body is consumed by req.text(),
  // so we must capture these before entering the try block.
  let rawBody = "";
  let molliePaymentId = "unknown";

  try {
    // 1. Read and validate body
    rawBody = await req.text();
    const payload = WebhookPayloadSchema.parse(JSON.parse(rawBody));
    molliePaymentId = payload.id;

    // 2. Authentication: HMAC for external Mollie calls, service_role for DLQ retries
    const isDlqRetry = req.headers.get("x-dlq-retry") === "true";

    if (isDlqRetry) {
      // C2: DLQ retries must authenticate with service_role JWT
      if (!verifyServiceRole(req)) {
        return jsonResponse({ error: "Unauthorized DLQ retry" }, 401);
      }
    } else {
      // External Mollie webhook — HMAC verification mandatory
      const signature = req.headers.get("x-mollie-signature");
      const webhookSecret = await getVaultSecret(supabase, "mollie_webhook_secret");
      const isValid = await verifySignature(rawBody, signature, webhookSecret);
      if (!isValid) {
        console.error(`[mollie-webhook] Invalid signature for ${molliePaymentId}`);
        return jsonResponse({ error: "Invalid signature" }, 401);
      }
    }

    // 3. Idempotency check via Upstash Redis NX (R-11: shared redis.ts)
    const redisCreds = getRedisCredentials();
    const idempotencyKey = `mollie:webhook:${molliePaymentId}`;
    const isNew = await checkIdempotency(redisCreds, idempotencyKey);
    if (!isNew) {
      console.log(`[mollie-webhook] Duplicate skipped: ${molliePaymentId}`);
      return new Response("Already processed", { status: 200 });
    }

    // 4. Fetch payment details from Mollie
    const mollieVaultKey = Deno.env.get("MOLLIE_VAULT_KEY") ?? "mollie_api_key";
    const mollieApiKey = await getVaultSecret(supabase, mollieVaultKey);
    const payment = await fetchMolliePayment(molliePaymentId, mollieApiKey);
    const transactionId = payment.metadata?.transaction_id;

    if (!transactionId) {
      console.error(`[mollie-webhook] No transaction_id in metadata for ${molliePaymentId}`);
      return jsonResponse({ error: "Missing transaction_id in metadata" }, 422);
    }

    // 5. Record webhook event — fail hard (PSD2 audit trail)
    const { error: eventError } = await supabase
      .from("mollie_webhook_events")
      .upsert(
        {
          mollie_id: molliePaymentId,
          event_type: payment.status,
          payload: payment,
          idempotency_key: idempotencyKey,
          processed: false,
          attempts: 1,
          last_attempted_at: new Date().toISOString(),
        },
        { onConflict: "idempotency_key" }
      );

    if (eventError) {
      throw new Error(`Failed to record webhook event: ${eventError.message}`);
    }

    // 6. Map Mollie status and update transaction
    const newStatus = mapMollieStatus(payment.status);

    if (newStatus) {
      const updateData: Record<string, unknown> = { status: newStatus };

      if (newStatus === "paid") {
        updateData.paid_at = new Date().toISOString();
        // B-21: escrow_deadline is set on delivery (48h buyer window),
        // not on payment. See release-escrow function.
      }

      const { error: updateError } = await supabase
        .from("transactions")
        .update(updateData)
        .eq("mollie_payment_id", molliePaymentId);

      if (updateError) {
        throw new Error(`Transaction update failed: ${updateError.message}`);
      }

      // 7. Record escrow split ledger entries — fail hard (double-entry integrity)
      // B-20: Two entries on payment: deposit + platform fee split
      if (newStatus === "paid") {
        const { data: txn } = await supabase
          .from("transactions")
          .select("id, buyer_id, seller_id, item_amount_cents, platform_fee_cents, shipping_cost_cents")
          .eq("mollie_payment_id", molliePaymentId)
          .single();

        if (txn) {
          const totalCents =
            txn.item_amount_cents + txn.platform_fee_cents + txn.shipping_cost_cents;

          // Entry 1: Full buyer payment → escrow
          const { error: depositError } = await supabase.from("ledger_entries").insert({
            transaction_id: txn.id,
            idempotency_key: `deposit:buyer:${txn.id}`,
            debit_account: `buyer:${txn.buyer_id}`,
            credit_account: `escrow:${txn.id}`,
            amount_cents: totalCents,
            currency: "EUR",
          });

          if (depositError) {
            throw new Error(`Failed to record escrow deposit: ${depositError.message}`);
          }

          // Entry 2: Platform fee split — escrow → platform commission
          // Immediately accounts for platform revenue on payment
          if (txn.platform_fee_cents > 0) {
            const { error: feeError } = await supabase.from("ledger_entries").insert({
              transaction_id: txn.id,
              idempotency_key: `fee:platform:${txn.id}`,
              debit_account: `escrow:${txn.id}`,
              credit_account: `platform:commission`,
              amount_cents: txn.platform_fee_cents,
              currency: "EUR",
            });

            if (feeError) {
              throw new Error(`Failed to record platform fee split: ${feeError.message}`);
            }
          }
        }
      }
    }

    // 8. Mark webhook event as processed
    await supabase
      .from("mollie_webhook_events")
      .update({
        processed: true,
        processed_at: new Date().toISOString(),
        last_attempted_at: new Date().toISOString(),
      })
      .eq("idempotency_key", idempotencyKey);

    console.log(
      `[mollie-webhook] Processed ${molliePaymentId}: ${payment.status} → ${newStatus ?? "no change"}`
    );
    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error(`[mollie-webhook] Error: ${(error as Error).message}`);

    // Rollback idempotency key so Mollie can retry (CRITICAL: without this, retries are blocked for 24h)
    const rollbackKey = `mollie:webhook:${molliePaymentId}`;
    try {
      const redisCreds = getRedisCredentials();
      await rollbackIdempotency(redisCreds, rollbackKey);
    } catch {
      // Best-effort rollback
    }

    // Record failure for DLQ — preserve existing state
    try {
      const { data: existing } = await supabase
        .from("mollie_webhook_events")
        .select("attempts, event_type")
        .eq("idempotency_key", rollbackKey)
        .single();

      await supabase
        .from("mollie_webhook_events")
        .upsert(
          {
            mollie_id: molliePaymentId,
            event_type: existing?.event_type ?? "error",
            payload: { error: (error as Error).message },
            idempotency_key: rollbackKey,
            processed: false,
            attempts: (existing?.attempts ?? 0) + 1,
            last_error: (error as Error).message,
            last_attempted_at: new Date().toISOString(),
          },
          { onConflict: "idempotency_key" }
        );
    } catch {
      // Best-effort error recording
    }

    return jsonResponse({ error: "Internal error" }, 500);
  }
});
