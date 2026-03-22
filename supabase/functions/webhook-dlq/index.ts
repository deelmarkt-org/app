/**
 * Webhook Dead Letter Queue (DLQ) Processor (B-19)
 *
 * Retries failed/unprocessed webhook events with exponential backoff.
 * After 5 failed attempts, sends PagerDuty SEV-1 alert (once per event).
 *
 * Retry schedule: 1s → 2s → 4s → 8s → DLQ (PagerDuty SEV-1)
 *
 * Scheduled via pg_cron every 5 minutes.
 *
 * Reference: docs/epics/E03-payments-escrow.md §Webhook Idempotency
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MAX_ATTEMPTS = 5;
// Backoff: 1s, 2s, 4s, 8s — capped at 8s per E03 spec
const MAX_BACKOFF_MS = 8000;

// ---------------------------------------------------------------------------
// PagerDuty SEV-1 alert (M7: log fallback)
// ---------------------------------------------------------------------------

async function triggerSev1Alert(
  routingKey: string,
  event: {
    id: string;
    mollie_id: string;
    attempts: number;
    last_error: string | null;
    created_at: string;
  }
): Promise<void> {
  try {
    const response = await fetch("https://events.pagerduty.com/v2/enqueue", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        routing_key: routingKey,
        event_action: "trigger",
        dedup_key: `dlq:${event.mollie_id}`,
        payload: {
          summary: `[DeelMarkt] SEV-1: Webhook DLQ — ${event.mollie_id} failed ${event.attempts} times`,
          source: "webhook-dlq",
          severity: "critical",
          component: "mollie-webhook",
          custom_details: {
            mollie_id: event.mollie_id,
            attempts: event.attempts,
            last_error: event.last_error,
            first_seen: event.created_at,
            action_required:
              "Manual investigation required. Check Mollie dashboard for payment status " +
              "and reconcile with ledger_entries table.",
          },
        },
      }),
    });

    if (!response.ok) {
      console.error(
        `[webhook-dlq] ALERT DELIVERY FAILED — PagerDuty returned ${response.status}. ` +
          `Event: ${event.mollie_id}, attempts: ${event.attempts}`
      );
    } else {
      console.log(`[webhook-dlq] SEV-1 alert sent for ${event.mollie_id}`);
    }
  } catch (err) {
    console.error(
      `[webhook-dlq] ALERT DELIVERY FAILED — PagerDuty unreachable: ${(err as Error).message}. ` +
        `Event: ${event.mollie_id}, attempts: ${event.attempts}`
    );
  }
}

// ---------------------------------------------------------------------------
// Retry a single webhook event
// ---------------------------------------------------------------------------

async function retryWebhookEvent(
  supabaseUrl: string,
  event: { id: string; mollie_id: string }
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`${supabaseUrl}/functions/v1/mollie-webhook`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // M5: DLQ retry header — webhook checks this to skip HMAC
        "x-dlq-retry": "true",
      },
      body: JSON.stringify({ id: event.mollie_id }),
    });

    if (response.ok) {
      return { success: true };
    }

    const text = await response.text();
    return { success: false, error: `HTTP ${response.status}: ${text}` };
  } catch (error) {
    return { success: false, error: (error as Error).message };
  }
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
  const pagerdutyKey = Deno.env.get("PAGERDUTY_ROUTING_KEY");

  try {
    // Fetch unprocessed events eligible for retry
    const { data: failedEvents, error } = await supabase
      .from("mollie_webhook_events")
      .select("id, mollie_id, payload, attempts, last_error, created_at, last_attempted_at")
      .eq("processed", false)
      .lt("attempts", MAX_ATTEMPTS)
      .order("created_at", { ascending: true })
      .limit(20);

    if (error) {
      throw new Error(`Failed to fetch DLQ events: ${error.message}`);
    }

    // H3: Fetch DLQ'd events that haven't been alerted yet
    const { data: dlqEvents } = await supabase
      .from("mollie_webhook_events")
      .select("id, mollie_id, attempts, last_error, created_at")
      .eq("processed", false)
      .gte("attempts", MAX_ATTEMPTS)
      .is("alerted_at", null)
      .order("created_at", { ascending: true })
      .limit(20);

    const results = {
      retried: 0,
      succeeded: 0,
      failed: 0,
      alerted: 0,
      timestamp: new Date().toISOString(),
    };

    // Retry eligible events with exponential backoff
    for (const event of failedEvents ?? []) {
      // M1: Use last_attempted_at for backoff timing (falls back to created_at)
      const backoffMs = Math.min(
        MAX_BACKOFF_MS,
        1000 * Math.pow(2, event.attempts)
      );
      const lastTime = event.last_attempted_at ?? event.created_at;
      const lastAttemptTime = new Date(lastTime).getTime();
      const now = Date.now();

      if (now - lastAttemptTime < backoffMs) {
        continue; // Not ready for retry yet
      }

      results.retried++;

      const { success, error: retryError } = await retryWebhookEvent(
        supabaseUrl,
        event
      );

      if (success) {
        results.succeeded++;
        await supabase
          .from("mollie_webhook_events")
          .update({
            processed: true,
            processed_at: new Date().toISOString(),
            attempts: event.attempts + 1,
            last_attempted_at: new Date().toISOString(),
          })
          .eq("id", event.id);
      } else {
        results.failed++;
        const newAttempts = event.attempts + 1;

        await supabase
          .from("mollie_webhook_events")
          .update({
            attempts: newAttempts,
            last_error: retryError ?? "Unknown error",
            last_attempted_at: new Date().toISOString(),
          })
          .eq("id", event.id);

        // Alert on reaching MAX_ATTEMPTS
        if (newAttempts >= MAX_ATTEMPTS && pagerdutyKey) {
          await triggerSev1Alert(pagerdutyKey, {
            ...event,
            attempts: newAttempts,
            last_error: retryError ?? event.last_error,
          });
          // H3: Mark as alerted to prevent duplicate alerts
          await supabase
            .from("mollie_webhook_events")
            .update({ alerted_at: new Date().toISOString() })
            .eq("id", event.id);
          results.alerted++;
        }
      }
    }

    // H3: Alert on DLQ'd events that haven't been alerted yet (not re-alerting)
    for (const event of dlqEvents ?? []) {
      if (pagerdutyKey) {
        await triggerSev1Alert(pagerdutyKey, event);
        await supabase
          .from("mollie_webhook_events")
          .update({ alerted_at: new Date().toISOString() })
          .eq("id", event.id);
        results.alerted++;
      }
    }

    const status = results.failed > 0 || (dlqEvents?.length ?? 0) > 0 ? "degraded" : "ok";

    console.log(
      `[webhook-dlq] ${status}: retried=${results.retried} succeeded=${results.succeeded} ` +
        `failed=${results.failed} alerted=${results.alerted}`
    );

    return new Response(JSON.stringify({ status, ...results }, null, 2), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(`[webhook-dlq] Error: ${(error as Error).message}`);
    return new Response(
      JSON.stringify({ status: "error", message: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
