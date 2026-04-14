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
 *   listing.created (includes reactivations):
 *     • INCR `search:cache:version`    — new/reactivated listing must appear
 *   listing.updated:
 *     • `listing:detail:{listingId}`   — detail page only
 *
 * Redis operations are parallelised with Promise.all and deduplicated to
 * avoid per-event sequential HTTP round-trips timing out on large batches.
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

function userProfileKey(sellerId: string): string {
  return `user:profile:${sellerId}`;
}

/** Increments the search cache version, busting all paginated search caches. */
async function bustSearchCache(
  creds: { url: string; token: string },
): Promise<void> {
  const response = await fetch(`${creds.url}/incr/search:cache:version`, {
    method: "POST",
    headers: { Authorization: `Bearer ${creds.token}` },
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

  // ── Redis credentials — fail fast on misconfiguration ─────────────────
  // A missing config is a deployment error, not a transient failure.
  // Return 500 so events remain unprocessed and the outbox retries next run.
  let redisCreds: { url: string; token: string };
  try {
    redisCreds = getRedisCredentials();
  } catch (err) {
    console.error("Redis configuration error — aborting outbox run:", err);
    return jsonResponse({ error: "Internal server error (Redis config)" }, 500);
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

  // ── Collect + deduplicate cache keys across all events ─────────────────
  // Deduplication avoids redundant Redis calls when the same listing has
  // multiple events in a single batch (e.g. updated → sold in quick succession).
  const detailKeysToDelete = new Set<string>();
  const profileKeysToDelete = new Set<string>();
  let needsSearchBust = false;

  // Track valid event IDs — malformed events (missing listing_id) are
  // excluded from the mark batch so they stay unprocessed for investigation.
  const validIds: string[] = [];

  for (const event of events) {
    const listingId = event.payload?.listing_id;
    const sellerId = event.payload?.seller_id;
    if (!listingId) {
      console.warn("Outbox event missing listing_id — skipping:", event.id);
      continue;
    }
    validIds.push(event.id);

    switch (event.event_type) {
      case "listing.sold":
      case "listing.deleted":
        detailKeysToDelete.add(listingDetailKey(listingId));
        if (sellerId) profileKeysToDelete.add(userProfileKey(sellerId));
        needsSearchBust = true;
        break;

      case "listing.created":
        // Covers new listings and reactivations (is_active: false→true or
        // is_sold: true→false). Both must appear in search results immediately.
        if (sellerId) profileKeysToDelete.add(userProfileKey(sellerId));
        needsSearchBust = true;
        break;

      case "listing.updated":
        detailKeysToDelete.add(listingDetailKey(listingId));
        // Title/price changes affect search result cards — bust search cache
        // so buyers see updated info within one cron cycle, not after TTL.
        needsSearchBust = true;
        break;
    }
  }

  if (validIds.length === 0) {
    console.warn("All events in batch were malformed — nothing to process");
    return jsonResponse({ processed: 0, skipped: events.length });
  }

  // ── Execute all Redis operations in parallel ───────────────────────────
  let cacheErrors = 0;

  const tasks: Promise<void>[] = [];

  for (const key of detailKeysToDelete) {
    tasks.push(
      redisDel(redisCreds, key).then(() => {}).catch((err) => {
        console.error(`Redis DEL failed for key ${key}:`, err);
        cacheErrors++;
      }),
    );
  }

  for (const key of profileKeysToDelete) {
    tasks.push(
      redisDel(redisCreds, key).then(() => {}).catch((err) => {
        console.error(`Redis DEL failed for key ${key}:`, err);
        cacheErrors++;
      }),
    );
  }

  if (needsSearchBust) {
    tasks.push(
      bustSearchCache(redisCreds).catch((err) => {
        console.error("Redis search cache bust failed:", err);
        cacheErrors++;
      }),
    );
  }

  await Promise.all(tasks);

  // ── Only mark as processed when all cache ops succeeded ────────────────
  // On cache failure, leave events unprocessed so the next cron run retries.
  // This prevents stale caches from persisting silently after Redis outages.
  if (cacheErrors > 0) {
    console.error(
      `process-search-outbox: ${cacheErrors} cache error(s) — ` +
        `leaving ${validIds.length} events unprocessed for retry`,
    );
    return jsonResponse(
      { processed: 0, cache_errors: cacheErrors, retrying: true },
      500,
    );
  }

  const { error: markError } = await supabase.rpc(
    "mark_outbox_events_processed",
    { p_ids: validIds },
  );

  if (markError) {
    console.error("Failed to mark outbox events as processed:", markError);
    return jsonResponse({ error: "Failed to mark events as processed" }, 500);
  }

  console.info(
    `process-search-outbox: processed ${validIds.length} events` +
      (validIds.length < events.length
        ? ` (${events.length - validIds.length} malformed — skipped)`
        : ""),
  );

  return jsonResponse({
    processed: validIds.length,
    skipped: events.length - validIds.length,
    search_busted: needsSearchBust,
    profile_keys_busted: profileKeysToDelete.size,
  });
});
