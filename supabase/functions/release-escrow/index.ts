/**
 * Release Escrow Edge Function (B-21, B-22, B-23)
 *
 * verify_jwt = false — triggered by pg_cron. Auth via service_role check.
 * Scheduled: every 15 minutes.
 *
 * Handles three release scenarios:
 * 1. Buyer confirmed delivery (status = confirmed) → release to seller
 * 2. 48-hour window expired after delivery (escrow_deadline < now) → auto-release
 * 3. 90-day hard limit exceeded (paid_at + 90 days < now) → force-release + alert
 *
 * Creates ledger entry: escrow → seller (sellerPayoutCents = item + shipping)
 * Platform fee was already split at payment time (B-20).
 *
 * Reference: docs/epics/E03-payments-escrow.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { triggerPagerDuty } from "../_shared/pagerduty.ts";
import { verifyServiceRole } from "../_shared/auth.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const ESCROW_HARD_LIMIT_DAYS = 90;

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  const pagerdutyKey = Deno.env.get("PAGERDUTY_ROUTING_KEY");
  const now = new Date().toISOString();

  const results = {
    confirmed_releases: 0,
    timeout_releases: 0,
    hard_limit_releases: 0,
    errors: 0,
    timestamp: now,
  };

  try {
    // -----------------------------------------------------------------------
    // 1. Release confirmed transactions (B-22)
    //    Buyer confirmed delivery → release seller payout
    // -----------------------------------------------------------------------
    const { data: confirmed, error: confirmedError } = await supabase
      .from("transactions")
      .select("id, seller_id, item_amount_cents, shipping_cost_cents")
      .eq("status", "confirmed");

    if (confirmedError) {
      throw new Error(`Failed to fetch confirmed txns: ${confirmedError.message}`);
    }

    for (const txn of confirmed ?? []) {
      try {
        await releaseToSeller(supabase, txn);
        results.confirmed_releases++;
      } catch (err) {
        console.error(`[release-escrow] Error releasing confirmed ${txn.id}: ${(err as Error).message}`);
        results.errors++;
      }
    }

    // -----------------------------------------------------------------------
    // 2. Auto-release expired escrow deadlines (B-23)
    //    48h window passed after delivery → auto-release to seller
    // -----------------------------------------------------------------------
    const { data: expired, error: expiredError } = await supabase
      .from("transactions")
      .select("id, seller_id, item_amount_cents, shipping_cost_cents")
      .eq("status", "delivered")
      .lt("escrow_deadline", now);

    if (expiredError) {
      throw new Error(`Failed to fetch expired txns: ${expiredError.message}`);
    }

    for (const txn of expired ?? []) {
      try {
        // Auto-confirm then release
        await supabase
          .from("transactions")
          .update({ status: "confirmed", confirmed_at: now })
          .eq("id", txn.id);

        await releaseToSeller(supabase, txn);
        results.timeout_releases++;
      } catch (err) {
        console.error(`[release-escrow] Error auto-releasing ${txn.id}: ${(err as Error).message}`);
        results.errors++;
      }
    }

    // -----------------------------------------------------------------------
    // 3. Force-release 90-day hard limit (B-21)
    //    Safety net — any escrow held >90 days is force-released with alert
    // -----------------------------------------------------------------------
    const hardLimitDate = new Date();
    hardLimitDate.setDate(hardLimitDate.getDate() - ESCROW_HARD_LIMIT_DAYS);

    const { data: stale, error: staleError } = await supabase
      .from("transactions")
      .select("id, seller_id, buyer_id, status, item_amount_cents, shipping_cost_cents, paid_at")
      // C1: Exclude 'disputed' — DB state machine only allows disputed → {resolved, refunded}
      // Disputed txns require manual resolution, not auto-release to seller
      .in("status", ["paid", "shipped", "delivered", "confirmed"])
      .lt("paid_at", hardLimitDate.toISOString());

    if (staleError) {
      throw new Error(`Failed to fetch stale txns: ${staleError.message}`);
    }

    for (const txn of stale ?? []) {
      try {
        // Force-confirm if not already confirmed
        if (txn.status !== "confirmed") {
          await supabase
            .from("transactions")
            .update({ status: "confirmed", confirmed_at: now })
            .eq("id", txn.id);
        }

        await releaseToSeller(supabase, txn);
        results.hard_limit_releases++;

        // Alert — 90-day force-release is unusual and needs investigation
        if (pagerdutyKey) {
          await triggerPagerDuty(
            pagerdutyKey,
            `90-day escrow force-release: txn ${txn.id} (status was ${txn.status})`,
            "warning",
            {
              transaction_id: txn.id,
              seller_id: txn.seller_id,
              buyer_id: txn.buyer_id,
              original_status: txn.status,
              paid_at: txn.paid_at,
              action: "Force-released after 90-day hard limit",
            },
            { source: "release-escrow", dedupKey: `90d:${txn.id}` }
          );
        }
      } catch (err) {
        console.error(`[release-escrow] Error force-releasing ${txn.id}: ${(err as Error).message}`);
        results.errors++;
      }
    }

    const total =
      results.confirmed_releases + results.timeout_releases + results.hard_limit_releases;
    const status = results.errors > 0 ? "degraded" : "ok";

    console.log(
      `[release-escrow] ${status}: confirmed=${results.confirmed_releases} ` +
        `timeout=${results.timeout_releases} hard_limit=${results.hard_limit_releases} ` +
        `errors=${results.errors}`
    );

    return jsonResponse({ status, ...results }, 200);
  } catch (error) {
    console.error(`[release-escrow] Error: ${(error as Error).message}`);
    return jsonResponse({ status: "error", message: (error as Error).message }, 500);
  }
});

// ---------------------------------------------------------------------------
// Release funds from escrow to seller
// ---------------------------------------------------------------------------

async function releaseToSeller(
  supabase: ReturnType<typeof createClient>,
  txn: { id: string; seller_id: string; item_amount_cents: number; shipping_cost_cents: number }
): Promise<void> {
  const sellerPayoutCents = txn.item_amount_cents + txn.shipping_cost_cents;

  // H1: Status update first — ledger entries are idempotent (UNIQUE key)
  // so they can be safely retried if status succeeds but ledger fails.
  // This prevents orphaned ledger entries with mismatched status.
  const { data: updated, error: updateError } = await supabase
    .from("transactions")
    .update({ status: "released", released_at: new Date().toISOString() })
    .eq("id", txn.id)
    .neq("status", "released")
    .select("id");

  if (updateError) {
    throw new Error(`Status update failed for ${txn.id}: ${updateError.message}`);
  }

  // 0 rows matched — already released
  if (!updated || updated.length === 0) {
    console.log(`[release-escrow] Already released: ${txn.id}`);
    return;
  }

  // Ledger entry: escrow → seller (idempotent via UNIQUE key)
  const { error: ledgerError } = await supabase.from("ledger_entries").insert({
    transaction_id: txn.id,
    idempotency_key: `release:seller:${txn.id}`,
    debit_account: `escrow:${txn.id}`,
    credit_account: `seller:${txn.seller_id}`,
    amount_cents: sellerPayoutCents,
    currency: "EUR",
  });

  // H2: Skip if already recorded (retry scenario — status updated, ledger exists)
  if (ledgerError?.code === "23505") {
    console.log(`[release-escrow] Ledger already exists for ${txn.id}, status updated`);
    return;
  }
  if (ledgerError) {
    throw new Error(`Ledger entry failed for ${txn.id}: ${ledgerError.message}`);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
