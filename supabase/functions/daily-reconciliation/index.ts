/**
 * Daily Reconciliation Edge Function (B-18)
 *
 * verify_jwt = false — triggered by pg_cron. Auth via service_role check.
 * Scheduled: daily at 06:00 UTC.
 *
 * Checks:
 * 1. Per-transaction ledger validation (batch query, no N+1)
 * 2. Unprocessed webhook events older than 30 minutes
 * 3. Escrow balance validation (debits == credits per released txn)
 *
 * Reference: docs/epics/E03-payments-escrow.md §Daily reconciliation
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { triggerPagerDuty } from "../_shared/pagerduty.ts";
import { verifyServiceRole } from "../_shared/auth.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Stuck event threshold — 30 minutes balances alerting speed vs tolerance
const STUCK_EVENT_THRESHOLD_MINUTES = 30;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CheckResult {
  name: string;
  passed: boolean;
  details: string;
  severity?: "SEV-1" | "SEV-2" | "INFO";
}

// ---------------------------------------------------------------------------
// Reconciliation checks
// ---------------------------------------------------------------------------

// H1: Batch query instead of N+1
async function checkPerTransactionLedger(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  const since = new Date();
  since.setHours(since.getHours() - 24);

  const { data: paidEvents, error: eventError } = await supabase
    .from("mollie_webhook_events")
    .select("mollie_id, payload")
    .eq("processed", true)
    .eq("event_type", "paid")
    .gte("created_at", since.toISOString());

  if (eventError) {
    return { name: "per_txn_ledger", passed: false, details: `Query error: ${eventError.message}`, severity: "SEV-2" };
  }

  if (!paidEvents || paidEvents.length === 0) {
    return { name: "per_txn_ledger", passed: true, details: "No paid events in last 24h", severity: "INFO" };
  }

  // Extract transaction IDs from event metadata
  const txnIds: string[] = [];
  for (const event of paidEvents) {
    const txnId = (event.payload as Record<string, Record<string, string>>)?.metadata?.transaction_id;
    if (txnId) txnIds.push(txnId);
  }

  if (txnIds.length === 0) {
    return { name: "per_txn_ledger", passed: false, details: "Paid events have no transaction_id in metadata", severity: "SEV-1" };
  }

  // Single batch query for all deposit keys
  const depositKeys = txnIds.map((id) => `deposit:buyer:${id}`);
  const { data: entries, error: ledgerError } = await supabase
    .from("ledger_entries")
    .select("idempotency_key")
    .in("idempotency_key", depositKeys);

  if (ledgerError) {
    return { name: "per_txn_ledger", passed: false, details: `Ledger query error: ${ledgerError.message}`, severity: "SEV-2" };
  }

  const foundKeys = new Set((entries ?? []).map((e) => e.idempotency_key));
  const missing = txnIds.filter((id) => !foundKeys.has(`deposit:buyer:${id}`));
  const passed = missing.length === 0;

  return {
    name: "per_txn_ledger",
    passed,
    details: passed
      ? `${paidEvents.length} paid events — all have matching deposits`
      : `${missing.length} missing deposits for txns: ${missing.join(", ")}`,
    severity: passed ? "INFO" : "SEV-1",
  };
}

async function checkStuckEvents(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  const threshold = new Date();
  threshold.setMinutes(threshold.getMinutes() - STUCK_EVENT_THRESHOLD_MINUTES);

  const { data: stuck, error } = await supabase
    .from("mollie_webhook_events")
    .select("id, mollie_id, created_at, attempts, last_error")
    .eq("processed", false)
    .lt("created_at", threshold.toISOString())
    .order("created_at", { ascending: true })
    .limit(50);

  if (error) {
    return { name: "stuck_events", passed: false, details: `Query error: ${error.message}`, severity: "SEV-2" };
  }

  const count = stuck?.length ?? 0;
  const passed = count === 0;

  return {
    name: "stuck_events",
    passed,
    details: passed
      ? `No stuck events (threshold: ${STUCK_EVENT_THRESHOLD_MINUTES}min)`
      : `${count} unprocessed events older than ${STUCK_EVENT_THRESHOLD_MINUTES}min: ${stuck!.map((e) => e.mollie_id).join(", ")}`,
    severity: passed ? "INFO" : "SEV-1",
  };
}

// M6: Single IN query instead of N+1
async function checkEscrowBalance(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  const { data: released, error } = await supabase
    .from("transactions")
    .select("id")
    .eq("status", "released")
    .limit(100);

  if (error) {
    return { name: "escrow_balance", passed: false, details: `Query error: ${error.message}`, severity: "SEV-2" };
  }

  if (!released || released.length === 0) {
    return { name: "escrow_balance", passed: true, details: "No released transactions to check", severity: "INFO" };
  }

  const txnIds = released.map((t) => t.id);
  const { data: allEntries, error: ledgerError } = await supabase
    .from("ledger_entries")
    .select("transaction_id, debit_account, credit_account, amount_cents")
    .in("transaction_id", txnIds);

  if (ledgerError) {
    return { name: "escrow_balance", passed: false, details: `Ledger query error: ${ledgerError.message}`, severity: "SEV-2" };
  }

  const imbalanced: string[] = [];

  for (const txn of released) {
    const entries = (allEntries ?? []).filter((e) => e.transaction_id === txn.id);
    const escrowAccount = `escrow:${txn.id}`;
    let debitsToEscrow = 0;
    let creditsFromEscrow = 0;

    for (const entry of entries) {
      if (entry.credit_account === escrowAccount) debitsToEscrow += entry.amount_cents;
      if (entry.debit_account === escrowAccount) creditsFromEscrow += entry.amount_cents;
    }

    if (debitsToEscrow !== creditsFromEscrow) {
      imbalanced.push(`${txn.id}: in=${debitsToEscrow} out=${creditsFromEscrow}`);
    }
  }

  const passed = imbalanced.length === 0;

  return {
    name: "escrow_balance",
    passed,
    details: passed
      ? `${released.length} released transactions — all balanced`
      : `${imbalanced.length} imbalanced: ${imbalanced.join("; ")}`,
    severity: passed ? "INFO" : "SEV-1",
  };
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // C3: Explicit service_role auth check (verify_jwt = false)
  if (!await verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  try {
    const checks = await Promise.all([
      checkPerTransactionLedger(supabase),
      checkStuckEvents(supabase),
      checkEscrowBalance(supabase),
    ]);

    const allPassed = checks.every((c) => c.passed);

    if (!allPassed) {
      const pagerdutyKey = Deno.env.get("PAGERDUTY_ROUTING_KEY");
      if (pagerdutyKey) {
        const failedChecks = checks.filter((c) => !c.passed);
        const hasSev1 = failedChecks.some((c) => c.severity === "SEV-1");

        await triggerPagerDuty(
          pagerdutyKey,
          `Reconciliation ${hasSev1 ? "CRITICAL" : "WARNING"}: ${failedChecks.map((c) => c.name).join(", ")}`,
          hasSev1 ? "critical" : "warning",
          { checks: failedChecks },
          { source: "daily-reconciliation" }
        );
      }

      console.error(`[reconciliation] MISMATCH: ${JSON.stringify(checks.filter((c) => !c.passed))}`);
    } else {
      console.log(`[reconciliation] All checks passed`);
    }

    return jsonResponse(
      { status: allPassed ? "ok" : "mismatch", checks, timestamp: new Date().toISOString() },
      allPassed ? 200 : 409
    );
  } catch (error) {
    console.error(`[reconciliation] Error: ${(error as Error).message}`);
    return jsonResponse({ status: "error", message: (error as Error).message }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
