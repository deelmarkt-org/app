/**
 * Mollie Webhook Edge Function
 *
 * B-15: Webhook idempotency via Upstash Redis NX
 * B-16: HMAC-SHA256 signature verification
 *
 * Flow:
 * 1. Verify HMAC-SHA256 signature (reject invalid) — skipped for DLQ retries
 * 2. Check idempotency via Redis NX (skip duplicates)
 * 3. Fetch payment status from Mollie API
 * 4. Record webhook event in DB (fail-hard if recording fails)
 * 5. Update transaction status + record ledger entries
 * 6. On failure: retry with exponential backoff, DLQ after 5th attempt
 *
 * Reference: docs/epics/E03-payments-escrow.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

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
// Zod input validation (§9: Edge Functions use Zod)
// ---------------------------------------------------------------------------

const WebhookPayloadSchema = z.object({
  id: z.string().min(1, "Payment ID is required"),
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
// Upstash Redis idempotency (B-15)
// ---------------------------------------------------------------------------

async function checkIdempotency(
  redisUrl: string,
  redisToken: string,
  key: string
): Promise<boolean> {
  // Atomic NX set with 24h TTL — returns "OK" only if key was newly set
  const response = await fetch(`${redisUrl}/set/${key}/1/EX/86400/NX`, {
    headers: { Authorization: `Bearer ${redisToken}` },
  });
  const data = await response.json();
  return data.result === "OK";
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
// Transaction status mapping: Mollie status → our transaction_status
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
      // open, pending, authorized — transient states during payment flow.
      // No transaction status change needed until paid/failed/expired.
      return null;
  }
}

// ---------------------------------------------------------------------------
// Vault secret retrieval
// ---------------------------------------------------------------------------

async function getVaultSecret(
  supabase: ReturnType<typeof createClient>,
  secretName: string
): Promise<string> {
  const { data, error } = await supabase.rpc("vault_read_secret", {
    p_name: secretName,
  });
  if (error || !data) {
    throw new Error(`Failed to read vault secret '${secretName}': ${error?.message}`);
  }
  return data;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  // Only accept POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    // 1. Read and validate body
    const rawBody = await req.text();
    const payload = WebhookPayloadSchema.parse(JSON.parse(rawBody));
    const molliePaymentId = payload.id;

    // 2. Verify HMAC-SHA256 signature (B-16)
    // Skip for internal DLQ retries (M5) — signature was verified on first attempt
    const isDlqRetry = req.headers.get("x-dlq-retry") === "true";

    if (!isDlqRetry) {
      // C2: HMAC verification is mandatory for external Mollie webhooks
      const signature = req.headers.get("x-mollie-signature");
      const webhookSecret = await getVaultSecret(supabase, "mollie_webhook_secret");
      const isValid = await verifySignature(rawBody, signature, webhookSecret);
      if (!isValid) {
        console.error(`[mollie-webhook] Invalid signature for ${molliePaymentId}`);
        return new Response(JSON.stringify({ error: "Invalid signature" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // 3. Idempotency check via Upstash Redis NX (B-15)
    const redisUrl = Deno.env.get("UPSTASH_REDIS_REST_URL");
    const redisToken = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");
    const idempotencyKey = `mollie:webhook:${molliePaymentId}`;

    if (redisUrl && redisToken) {
      const isNew = await checkIdempotency(redisUrl, redisToken, idempotencyKey);
      if (!isNew) {
        console.log(`[mollie-webhook] Duplicate skipped: ${molliePaymentId}`);
        return new Response("Already processed", { status: 200 });
      }
    } else {
      console.warn(`[mollie-webhook] Redis not configured — idempotency check skipped`);
    }

    // 4. Fetch payment details from Mollie
    const mollieApiKey = await getVaultSecret(supabase, "mollie_test_api_key");
    const payment = await fetchMolliePayment(molliePaymentId, mollieApiKey);
    const transactionId = payment.metadata?.transaction_id;

    // M3: Return 422 so Mollie retries (200 would signal success)
    if (!transactionId) {
      console.error(`[mollie-webhook] No transaction_id in metadata for ${molliePaymentId}`);
      return new Response(JSON.stringify({ error: "Missing transaction_id in metadata" }), {
        status: 422,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 5. Record webhook event in DB (for reconciliation — B-18)
    // H1: Fail hard if event recording fails — PSD2 audit trail integrity
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
      const timestampField = newStatus === "paid" ? "paid_at" : null;
      const updateData: Record<string, unknown> = { status: newStatus };
      if (timestampField) {
        updateData[timestampField] = new Date().toISOString();
      }

      // Set escrow deadline (48h) when paid
      if (newStatus === "paid") {
        const deadline = new Date();
        deadline.setHours(deadline.getHours() + 48);
        updateData.escrow_deadline = deadline.toISOString();
      }

      const { error: updateError } = await supabase
        .from("transactions")
        .update(updateData)
        .eq("mollie_payment_id", molliePaymentId);

      if (updateError) {
        throw new Error(`Transaction update failed: ${updateError.message}`);
      }

      // 7. Record escrow deposit ledger entry when payment completes
      // C3: Fail hard if ledger entry fails — double-entry integrity
      if (newStatus === "paid") {
        const { data: txn } = await supabase
          .from("transactions")
          .select("id, buyer_id, item_amount_cents, platform_fee_cents, shipping_cost_cents")
          .eq("mollie_payment_id", molliePaymentId)
          .single();

        if (txn) {
          const totalCents =
            txn.item_amount_cents + txn.platform_fee_cents + txn.shipping_cost_cents;

          const { error: ledgerError } = await supabase.from("ledger_entries").insert({
            transaction_id: txn.id,
            idempotency_key: `deposit:buyer:${txn.id}`,
            debit_account: `buyer:${txn.buyer_id}`,
            credit_account: `escrow:${txn.id}`,
            amount_cents: totalCents,
            currency: "EUR",
          });

          if (ledgerError) {
            throw new Error(`Failed to record escrow deposit ledger: ${ledgerError.message}`);
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

    // M2: Record failure for DLQ — increment existing attempts, preserve original event_type
    try {
      const bodyText = await req.clone().text().catch(() => "");
      const parsed = JSON.parse(bodyText).id ?? "unknown";
      const key = `mollie:webhook:${parsed}`;

      // Check if event already exists to preserve state
      const { data: existing } = await supabase
        .from("mollie_webhook_events")
        .select("attempts, event_type")
        .eq("idempotency_key", key)
        .single();

      await supabase
        .from("mollie_webhook_events")
        .upsert(
          {
            mollie_id: parsed,
            event_type: existing?.event_type ?? "error",
            payload: { error: (error as Error).message },
            idempotency_key: key,
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

    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
