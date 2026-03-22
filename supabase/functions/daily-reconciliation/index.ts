/**
 * Daily Reconciliation Edge Function (B-18)
 *
 * Compares ledger entry count vs Mollie webhook event count per day.
 * Any mismatch triggers a PagerDuty SEV-1 alert.
 *
 * Designed to run as a daily cron job via pg_cron (06:00 UTC).
 *
 * Checks:
 * 1. Per-transaction ledger validation (each paid txn has deposit entry)
 * 2. Unprocessed webhook events older than 30 minutes (stuck events)
 * 3. Escrow balance validation (debits must equal credits per released transaction)
 *
 * L2: Stuck event threshold is 30 minutes — chosen to balance between
 * alerting speed and tolerance for Mollie processing delays.
 *
 * Reference: docs/epics/E03-payments-escrow.md §Daily reconciliation
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// L2: Stuck event threshold — 30 minutes balances alerting speed vs tolerance
const STUCK_EVENT_THRESHOLD_MINUTES = 30;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ReconciliationResult {
  status: "ok" | "mismatch";
  checks: CheckResult[];
  timestamp: string;
}

interface CheckResult {
  name: string;
  passed: boolean;
  details: string;
  severity?: "SEV-1" | "SEV-2" | "INFO";
}

// ---------------------------------------------------------------------------
// PagerDuty alert (M7: log fallback if PagerDuty fails)
// ---------------------------------------------------------------------------

async function triggerPagerDuty(
  routingKey: string,
  summary: string,
  severity: "critical" | "error" | "warning" | "info",
  details: Record<string, unknown>
): Promise<void> {
  try {
    const response = await fetch("https://events.pagerduty.com/v2/enqueue", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        routing_key: routingKey,
        event_action: "trigger",
        payload: {
          summary: `[DeelMarkt] ${summary}`,
          source: "daily-reconciliation",
          severity,
          custom_details: details,
        },
      }),
    });

    if (!response.ok) {
      // M7: Fallback — log critical error so Supabase Edge Function logs capture it
      console.error(
        `[reconciliation] ALERT DELIVERY FAILED — PagerDuty returned ${response.status}. ` +
          `Original alert: ${summary}. Details: ${JSON.stringify(details)}`
      );
    }
  } catch (err) {
    // M7: PagerDuty is down — log the full alert content as a fallback
    console.error(
      `[reconciliation] ALERT DELIVERY FAILED — PagerDuty unreachable: ${(err as Error).message}. ` +
        `Original alert: ${summary}. Details: ${JSON.stringify(details)}`
    );
  }
}

// ---------------------------------------------------------------------------
// Reconciliation checks
// ---------------------------------------------------------------------------

// C1: Per-transaction validation instead of broken count comparison.
// M4: Accounts for different event types (paid=1 entry, confirmed=2 entries).
async function checkPerTransactionLedger(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  const since = new Date();
  since.setHours(since.getHours() - 24);
  const sinceISO = since.toISOString();

  // Get all paid webhook events in last 24h
  const { data: paidEvents, error: eventError } = await supabase
    .from("mollie_webhook_events")
    .select("mollie_id, event_type, payload")
    .eq("processed", true)
    .eq("event_type", "paid")
    .gte("created_at", sinceISO);

  if (eventError) {
    return {
      name: "per_txn_ledger",
      passed: false,
      details: `Query error: ${eventError.message}`,
      severity: "SEV-2",
    };
  }

  if (!paidEvents || paidEvents.length === 0) {
    return {
      name: "per_txn_ledger",
      passed: true,
      details: "No paid events in last 24h — nothing to reconcile",
      severity: "INFO",
    };
  }

  // For each paid event, verify a deposit ledger entry exists
  const missingDeposits: string[] = [];

  for (const event of paidEvents) {
    const txnId = (event.payload as Record<string, unknown>)?.metadata
      ? ((event.payload as Record<string, Record<string, string>>).metadata?.transaction_id)
      : null;

    if (!txnId) {
      missingDeposits.push(`${event.mollie_id}: no transaction_id in metadata`);
      continue;
    }

    const { data: entry } = await supabase
      .from("ledger_entries")
      .select("id")
      .eq("idempotency_key", `deposit:buyer:${txnId}`)
      .single();

    if (!entry) {
      missingDeposits.push(`${event.mollie_id}: missing deposit for txn ${txnId}`);
    }
  }

  const passed = missingDeposits.length === 0;

  return {
    name: "per_txn_ledger",
    passed,
    details: passed
      ? `${paidEvents.length} paid events — all have matching ledger deposits`
      : `${missingDeposits.length} missing deposits: ${missingDeposits.join("; ")}`,
    severity: passed ? "INFO" : "SEV-1",
  };
}

async function checkStuckEvents(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  // L2: Threshold documented — 30 minutes
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
    return {
      name: "stuck_events",
      passed: false,
      details: `Query error: ${error.message}`,
      severity: "SEV-2",
    };
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

// M6: Single query instead of N+1
async function checkEscrowBalance(
  supabase: ReturnType<typeof createClient>
): Promise<CheckResult> {
  const { data: released, error } = await supabase
    .from("transactions")
    .select("id")
    .eq("status", "released")
    .limit(100);

  if (error) {
    return {
      name: "escrow_balance",
      passed: false,
      details: `Query error: ${error.message}`,
      severity: "SEV-2",
    };
  }

  if (!released || released.length === 0) {
    return {
      name: "escrow_balance",
      passed: true,
      details: "No released transactions to check",
      severity: "INFO",
    };
  }

  // Single query for all ledger entries of released transactions
  const txnIds = released.map((t) => t.id);
  const { data: allEntries, error: ledgerError } = await supabase
    .from("ledger_entries")
    .select("transaction_id, debit_account, credit_account, amount_cents")
    .in("transaction_id", txnIds);

  if (ledgerError) {
    return {
      name: "escrow_balance",
      passed: false,
      details: `Ledger query error: ${ledgerError.message}`,
      severity: "SEV-2",
    };
  }

  // Group entries by transaction and check balance
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
      imbalanced.push(
        `${txn.id}: in=${debitsToEscrow} out=${creditsFromEscrow} diff=${debitsToEscrow - creditsFromEscrow}`
      );
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
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    const checks = await Promise.all([
      checkPerTransactionLedger(supabase),
      checkStuckEvents(supabase),
      checkEscrowBalance(supabase),
    ]);

    const allPassed = checks.every((c) => c.passed);
    const result: ReconciliationResult = {
      status: allPassed ? "ok" : "mismatch",
      checks,
      timestamp: new Date().toISOString(),
    };

    if (!allPassed) {
      const pagerdutyKey = Deno.env.get("PAGERDUTY_ROUTING_KEY");
      if (pagerdutyKey) {
        const failedChecks = checks.filter((c) => !c.passed);
        const hasSev1 = failedChecks.some((c) => c.severity === "SEV-1");

        await triggerPagerDuty(
          pagerdutyKey,
          `Reconciliation ${hasSev1 ? "CRITICAL" : "WARNING"}: ${failedChecks.map((c) => c.name).join(", ")}`,
          hasSev1 ? "critical" : "warning",
          { checks: failedChecks }
        );
      }

      console.error(`[reconciliation] MISMATCH: ${JSON.stringify(checks.filter((c) => !c.passed))}`);
    } else {
      console.log(`[reconciliation] All checks passed at ${result.timestamp}`);
    }

    return new Response(JSON.stringify(result, null, 2), {
      status: allPassed ? 200 : 409,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(`[reconciliation] Error: ${(error as Error).message}`);
    return new Response(
      JSON.stringify({ status: "error", message: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
