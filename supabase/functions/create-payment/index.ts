/**
 * Create Payment Edge Function (B-14)
 *
 * Called by the Flutter app to initiate a Mollie iDEAL payment.
 * verify_jwt = true — requires authenticated user JWT.
 *
 * Reference: docs/epics/E03-payments-escrow.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { getRedisCredentials } from "../_shared/redis.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

// ---------------------------------------------------------------------------
// Zod input validation (§9)
// ---------------------------------------------------------------------------

const CreatePaymentSchema = z.object({
  transaction_id: z.string().uuid("Invalid transaction ID"),
  redirect_url: z.string().url("Invalid redirect URL"),
  description: z.string().max(140).optional(),
});

// ---------------------------------------------------------------------------
// Mollie payment creation
// ---------------------------------------------------------------------------

interface MollieCreateResponse {
  id: string;
  status: string;
  _links: {
    checkout?: { href: string };
  };
  expiresAt?: string;
}

async function createMolliePayment(
  apiKey: string,
  params: {
    amountCents: number;
    currency: string;
    description: string;
    redirectUrl: string;
    webhookUrl: string;
    transactionId: string;
    method: string;
  }
): Promise<MollieCreateResponse> {
  const amount = (params.amountCents / 100).toFixed(2);

  const response = await fetch("https://api.mollie.com/v2/payments", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: { currency: params.currency, value: amount },
      description: params.description,
      redirectUrl: params.redirectUrl,
      webhookUrl: params.webhookUrl,
      method: params.method,
      metadata: { transaction_id: params.transactionId },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Mollie API error (${response.status}): ${body}`);
  }

  return response.json();
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonError("Missing Authorization header", 401);
  }

  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  try {
    const body = await req.json();
    const input = CreatePaymentSchema.parse(body);

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return jsonError("Unauthorized", 401);
    }

    // M-01: Per-user rate limiting — max 10 payment creations per hour.
    // Prevents abuse (spam payment objects at Mollie) and credential stuffing.
    // Fails open if Redis is unavailable — payment availability > rate limiting.
    try {
      const redisCreds = getRedisCredentials();
      const { allowed, remaining, resetSeconds } = await checkRateLimit(
        redisCreds, user.id, "create-payment",
        { maxRequests: 10, windowSeconds: 3600 },
      );
      if (!allowed) {
        return new Response(
          JSON.stringify({
            error: "Too many payment requests. Please wait before trying again.",
            retry_after_seconds: resetSeconds,
          }),
          {
            status: 429,
            headers: {
              "Content-Type": "application/json",
              "Retry-After": String(resetSeconds),
              "X-RateLimit-Remaining": "0",
            },
          },
        );
      }
      // Expose remaining quota in response headers (informational)
      // Note: headers added to success response below
      console.log(`[create-payment] Rate limit: ${remaining} remaining for user ${user.id.slice(0, 8)}`);
    } catch (rateLimitErr) {
      // Fail open — log and continue
      console.warn(`[create-payment] Rate limit check failed, proceeding: ${(rateLimitErr as Error).message}`);
    }

    const { data: txn, error: txnError } = await serviceClient
      .from("transactions")
      .select("*")
      .eq("id", input.transaction_id)
      .single();

    if (txnError || !txn) {
      return jsonError("Transaction not found", 404);
    }

    if (txn.buyer_id !== user.id) {
      return jsonError("Only the buyer can initiate payment", 403);
    }

    // Only 'created' can transition to payment_pending — matches Dart TransactionStatus
    if (txn.status !== "created") {
      return jsonError(
        `Cannot create payment for transaction in '${txn.status}' state. Only 'created' transactions can initiate payment.`,
        409
      );
    }

    const totalCents =
      txn.item_amount_cents + txn.platform_fee_cents + txn.shipping_cost_cents;

    const mollieApiKey = await getVaultSecret(serviceClient, "mollie_test_api_key");
    const webhookUrl = `${supabaseUrl}/functions/v1/mollie-webhook`;

    const molliePayment = await createMolliePayment(mollieApiKey, {
      amountCents: totalCents,
      currency: txn.currency,
      description: input.description ?? `DeelMarkt #${input.transaction_id.slice(0, 8)}`,
      redirectUrl: input.redirect_url,
      webhookUrl,
      transactionId: input.transaction_id,
      method: "ideal",
    });

    if (!molliePayment._links.checkout?.href) {
      throw new Error("Mollie did not return a checkout URL");
    }

    const { error: statusError } = await serviceClient
      .from("transactions")
      .update({
        status: "payment_pending",
        mollie_payment_id: molliePayment.id,
      })
      .eq("id", input.transaction_id);

    if (statusError) {
      throw new Error(`Failed to update transaction: ${statusError.message}`);
    }

    console.log(
      `[create-payment] Created ${molliePayment.id} for txn ${input.transaction_id}`
    );

    return new Response(
      JSON.stringify({
        mollie_payment_id: molliePayment.id,
        checkout_url: molliePayment._links.checkout.href,
        expires_at: molliePayment.expiresAt ?? null,
      }),
      { status: 201, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return jsonError(
        `Validation error: ${error.errors.map((e) => e.message).join(", ")}`,
        400
      );
    }

    console.error(`[create-payment] Error: ${(error as Error).message}`);
    return jsonError("Internal error", 500);
  }
});

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
