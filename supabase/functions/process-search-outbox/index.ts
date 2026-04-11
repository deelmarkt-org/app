/**
 * R-30: process-search-outbox — Redis cache invalidation cron.
 *
 * Polls the search_outbox table for unprocessed listing events and
 * invalidates the relevant Upstash Redis cache keys, ensuring sold and
 * deleted listings are removed from buyer-facing views within one cron cycle.
 *
 * Cache keys invalidated per event type:
 *   listing.sold / listing.deleted:
 *     • `listing:detail:{listingId}`   — detail page cache
 *     • INCR `search:cache:version`    — busts all search-result caches
 *   listing.updated:
 *     • `listing:detail:{listingId}`   — detail page only
 *   listing.created:
 *     • INCR `search:cache:version`    — new listing must appear in results
 *
 * Auth: verify_jwt = false — triggered by pg_cron (service_role header).
 *
 * Schedule (pg_cron — run once after enabling extension):
 *   SELECT cron.schedule(
 *     'process-search-outbox',
 *     '* * * * *',  -- every minute
 *     $$SELECT net.http_post(
 *       url := current_setting('app.supabase_url') || '/functions/v1/process-search-outbox',
 *       headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key')),
 *       body := '{}'::jsonb
 *     ) AS request_id$$
 *   );
 *
 * Reference: docs/epics/E01-listing-management.md §"Outbox pattern"
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";
import { getRedisCredentials, redisDel } from "../_shared/redis.ts";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** Max events processed per cron invocation — prevents run-away batches. */
const BATCH_LIMIT = 200;

// ---------------------------------------------------------------------------
// Cache key helpers
// ---------------------------------------------------------------------------

function listingDetailKey(listingId: string): string {
  return `listing:detail:${listingId}`;
}

/** Increments the search cache version, effectively busting all search caches. */
async function bustSearchCache(
  redisUrl: string,
  redisToken: string,
): Promise<void> {
  const response = await fetch(`${redisUrl}/incr/search:cache:version`, {
    method: "POST",
    headers: { Authorization: `Bearer ${redisToken}` },
  });
  if (!response.ok) {
    throw new Error(
      `Redis INCR search:cache:version failed (HTTP ${response.status})`,
    );
  }
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface OutboxRow {
  id: string;
  event_type:
    | "listing.created"
    | "listing.updated"
    | "listing.sold"
    | "listing.deleted";
  payload: {
    listing_id: string;
    seller_id: string;
    is_active: boolean;
    is_sold: boolean;
  };
  created_at: string;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // ── Fetch unprocessed events (oldest first, bounded batch) ─────────────
  const { data: events, error: fetchError } = await supabase
    .from("search_outbox")
    .select("id, event_type, payload, created_at")
    .eq("processed", false)
    .order("created_at", { ascending: true })
    .limit(BATCH_LIMIT)
    .returns<OutboxRow[]>();

  if (fetchError) {
    console.error("Failed to fetch search_outbox events:", fetchError);
    return jsonResponse({ error: "Failed to fetch outbox events" }, 500);
  }

  if (!events || events.length === 0) {
    return jsonResponse({ processed: 0, message: "No pending events" });
  }

  // ── Invalidate Redis caches ────────────────────────────────────────────
  let redisCreds: { url: string; token: string };
  try {
    redisCreds = getRedisCredentials();
  } catch (err) {
    // Redis unavailable — skip cache invalidation, still mark as processed
    // to avoid the outbox growing unboundedly. Log for ops alerting.
    console.error("Redis unavailable — skipping cache invalidation:", err);
    redisCreds = { url: "", token: "" };
  }

  const failedIds: string[] = [];
  let searchCachebusted = false;

  for (const event of events) {
    const listingId = event.payload?.listing_id;
    if (!listingId) {
      console.warn("Outbox event missing listing_id:", event.id);
      continue;
    }

    try {
      if (redisCreds.url) {
        switch (event.event_type) {
          case "listing.sold":
          case "listing.deleted":
            // High-priority: remove detail page + bust search results
            await redisDel(redisCreds, listingDetailKey(listingId));
            if (!searchCachebusted) {
              await bustSearchCache(redisCreds.url, redisCreds.token);
              searchCachebusted = true; // one INCR per batch is enough
            }
            break;

          case "listing.updated":
            // Detail page may be stale; search results will naturally expire
            await redisDel(redisCreds, listingDetailKey(listingId));
            break;

          case "listing.created":
            // New listing should appear in search results immediately
            if (!searchCachebusted) {
              await bustSearchCache(redisCreds.url, redisCreds.token);
              searchCachebusted = true;
            }
            break;
        }
      }
    } catch (cacheErr) {
      // Cache errors must not block the outbox from advancing — log and
      // continue; the event will still be marked as processed.
      console.error(
        `Cache invalidation failed for listing ${listingId} (event ${event.event_type}):`,
        cacheErr,
      );
      failedIds.push(event.id);
    }
  }

  // ── Mark batch as processed ────────────────────────────────────────────
  const allIds = events.map((e) => e.id);
  const { error: markError } = await supabase.rpc(
    "mark_outbox_events_processed",
    { p_ids: allIds },
  );

  if (markError) {
    console.error("Failed to mark outbox events as processed:", markError);
    return jsonResponse({ error: "Failed to mark events as processed" }, 500);
  }

  console.info(
    `process-search-outbox: processed ${allIds.length} events` +
      (failedIds.length > 0
        ? ` (${failedIds.length} cache errors — events still marked processed)`
        : ""),
  );

  return jsonResponse({
    processed: allIds.length,
    cache_errors: failedIds.length,
    search_busted: searchCachebusted,
  });
});
