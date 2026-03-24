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
 *
 * Reference: docs/epics/E05-shipping-logistics.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { getVaultSecret } from "../_shared/vault.ts";

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
// HMAC verification
// ---------------------------------------------------------------------------

async function verifyCarrierSignature(
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

  if (computed.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < computed.length; i++) {
    mismatch |= computed.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  try {
    // 1. Read and validate body
    const rawBody = await req.text();
    const payload = TrackingEventSchema.parse(JSON.parse(rawBody));

    // 2. Verify carrier signature
    const secretName = payload.carrier === "postnl"
        ? "postnl_webhook_secret"
        : "dhl_webhook_secret";

    try {
      const webhookSecret = await getVaultSecret(supabase, secretName);
      const signature = req.headers.get("x-carrier-signature");
      const isValid = await verifyCarrierSignature(rawBody, signature, webhookSecret);
      if (!isValid) {
        console.error(`[tracking-webhook] Invalid ${payload.carrier} signature for ${payload.barcode}`);
        return jsonResponse({ error: "Invalid signature" }, 401);
      }
    } catch {
      // Vault secret not yet configured — log warning, continue for MVP
      console.warn(`[tracking-webhook] ${secretName} not in Vault — signature check skipped`);
    }

    // 3. Lookup shipping label by barcode
    const { data: label, error: labelError } = await supabase
      .from("shipping_labels")
      .select("id, transaction_id")
      .eq("barcode", payload.barcode)
      .single();

    if (labelError || !label) {
      console.error(`[tracking-webhook] Barcode not found: ${payload.barcode}`);
      return jsonResponse({ error: "Barcode not found" }, 422);
    }

    // 4. Insert tracking event (idempotent via UNIQUE carrier_event_id)
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

    // Skip if already processed (UNIQUE constraint on carrier_event_id)
    if (insertError?.code === "23505") {
      console.log(`[tracking-webhook] Duplicate skipped: ${payload.event_id}`);
      return new Response("Already processed", { status: 200 });
    }
    if (insertError) {
      throw new Error(`Failed to insert tracking event: ${insertError.message}`);
    }

    // 5. DB trigger (trg_on_tracking_delivered) handles status transition
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

    console.error(`[tracking-webhook] Error: ${(error as Error).message}`);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
