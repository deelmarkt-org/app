/**
 * Webhook Dead Letter Queue (DLQ) Processor (B-19)
 *
 * verify_jwt = false — triggered by pg_cron. Auth via service_role check.
 * Scheduled: every 5 minutes.
 *
 * Retry schedule: 1s → 2s → 4s → 8s → DLQ (PagerDuty SEV-1)
 *
 * Reference: docs/epics/E03-payments-escrow.md §Webhook Idempotency
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { triggerPagerDuty } from "../_shared/pagerduty.ts";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MAX_ATTEMPTS = 5;
const MAX_BACKOFF_MS = 8000; // Cap at 8s per E03 spec

// ---------------------------------------------------------------------------
// Retry a single webhook event
// ---------------------------------------------------------------------------

async function retryWebhookEvent(
  supabaseUrl: string,
  serviceRoleKey: string,
  event: { id: string; mollie_id: string },
): Promise<{ success: boolean; error?: string }> {
  try {
    // C2: DLQ retries authenticate with service_role JWT
    const response = await fetch(`${supabaseUrl}/functions/v1/mollie-webhook`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${serviceRoleKey}`,
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
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // C3: Explicit service_role auth check (verify_jwt = false)
  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const pagerdutyKey = Deno.env.get("PAGERDUTY_ROUTING_KEY");

  try {
    // Fetch retryable events
    const { data: failedEvents, error } = await supabase
      .from("mollie_webhook_events")
      .select(
        "id, mollie_id, payload, attempts, last_error, created_at, last_attempted_at",
      )
      .eq("processed", false)
      .lt("attempts", MAX_ATTEMPTS)
      .order("created_at", { ascending: true })
      .limit(20);

    if (error) {
      throw new Error(`Failed to fetch DLQ events: ${error.message}`);
    }

    // H3: Only alert DLQ'd events not yet alerted
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

    for (const event of failedEvents ?? []) {
      // M1: Backoff from last_attempted_at, capped at 8s
      const backoffMs = Math.min(
        MAX_BACKOFF_MS,
        1000 * Math.pow(2, event.attempts),
      );
      const lastTime = event.last_attempted_at ?? event.created_at;
      const elapsed = Date.now() - new Date(lastTime).getTime();

      if (elapsed < backoffMs) continue;

      results.retried++;

      const { success, error: retryError } = await retryWebhookEvent(
        supabaseUrl,
        serviceRoleKey,
        event,
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

        if (newAttempts >= MAX_ATTEMPTS && pagerdutyKey) {
          await triggerPagerDuty(
            pagerdutyKey,
            `SEV-1: Webhook DLQ — ${event.mollie_id} failed ${newAttempts} times`,
            "critical",
            {
              mollie_id: event.mollie_id,
              attempts: newAttempts,
              last_error: retryError ?? event.last_error,
              first_seen: event.created_at,
            },
            {
              source: "webhook-dlq",
              dedupKey: `dlq:${event.mollie_id}`,
              component: "mollie-webhook",
            },
          );
          await supabase.from("mollie_webhook_events").update({
            alerted_at: new Date().toISOString(),
          }).eq("id", event.id);
          results.alerted++;
        }
      }
    }

    // H3: Alert un-alerted DLQ'd events
    for (const event of dlqEvents ?? []) {
      if (pagerdutyKey) {
        await triggerPagerDuty(
          pagerdutyKey,
          `SEV-1: Webhook DLQ — ${event.mollie_id} failed ${event.attempts} times`,
          "critical",
          {
            mollie_id: event.mollie_id,
            attempts: event.attempts,
            last_error: event.last_error,
            first_seen: event.created_at,
          },
          {
            source: "webhook-dlq",
            dedupKey: `dlq:${event.mollie_id}`,
            component: "mollie-webhook",
          },
        );
        await supabase.from("mollie_webhook_events").update({
          alerted_at: new Date().toISOString(),
        }).eq("id", event.id);
        results.alerted++;
      }
    }

    const status = results.failed > 0 || (dlqEvents?.length ?? 0) > 0
      ? "degraded"
      : "ok";
    console.log(
      `[webhook-dlq] ${status}: retried=${results.retried} succeeded=${results.succeeded} failed=${results.failed} alerted=${results.alerted}`,
    );

    return jsonResponse({ status, ...results }, 200);
  } catch (error) {
    console.error(`[webhook-dlq] Error: ${(error as Error).message}`);
    return jsonResponse(
      { status: "error", message: (error as Error).message },
      500,
    );
  }
});
