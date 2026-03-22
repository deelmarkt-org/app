/**
 * Create Payment Edge Function (B-14)
 *
 * Called by the Flutter app to initiate a Mollie iDEAL payment.
 *
 * Flow:
 * 1. Validate input (Zod)
 * 2. Verify the transaction belongs to the authenticated buyer
 * 3. Check transaction is in valid state for payment
 * 4. Create Mollie payment via API
 * 5. Store mollie_payment_id on transaction
 * 6. Transition status to payment_pending
 * 7. Return checkout URL for WebView
 *
 * Reference: docs/epics/E03-payments-escrow.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// ---------------------------------------------------------------------------
// Zod input validation (§9)
// ---------------------------------------------------------------------------

const CreatePaymentSchema = z.object({
  transaction_id: z.string().uuid("Invalid transaction ID"),
  redirect_url: z.string().url("Invalid redirect URL"),
  description: z.string().max(140).optional(),
});

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
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Use the user's JWT for auth checks, service_role for writes
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonError("Missing Authorization header", 401);
  }

  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  try {
    // 1. Validate input
    const body = await req.json();
    const input = CreatePaymentSchema.parse(body);

    // 2. Get authenticated user
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return jsonError("Unauthorized", 401);
    }

    // 3. Fetch transaction and verify ownership
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

    // 4. Validate transaction state — only 'created' can transition to payment_pending
    // H2: Matches Dart TransactionStatus.validTransitions (created → {paymentPending, cancelled})
    // expired/failed/cancelled are terminal states — buyer must create a new transaction
    if (txn.status !== "created") {
      return jsonError(
        `Cannot create payment for transaction in '${txn.status}' state. Only 'created' transactions can initiate payment.`,
        409
      );
    }

    // 5. Calculate total
    const totalCents =
      txn.item_amount_cents + txn.platform_fee_cents + txn.shipping_cost_cents;

    // 6. Create Mollie payment
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

    // 7. Update transaction — status first (atomicity pattern from B-15)
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

    // 8. Return checkout URL
    console.log(
      `[create-payment] Created ${molliePayment.id} for txn ${input.transaction_id}`
    );

    return new Response(
      JSON.stringify({
        mollie_payment_id: molliePayment.id,
        checkout_url: molliePayment._links.checkout.href,
        expires_at: molliePayment.expiresAt ?? null,
      }),
      {
        status: 201,
        headers: { "Content-Type": "application/json" },
      }
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

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
