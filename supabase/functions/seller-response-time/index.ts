/**
 * Seller Response Time Edge Function (R-33)
 *
 * verify_jwt = false — triggered by pg_cron. Auth via service_role check.
 * Scheduled: daily at 02:00 UTC.
 *
 * Algorithm:
 *   For each seller with at least one conversation in the last 90 days:
 *   1. Find all conversations where the seller is the listing owner.
 *   2. For each conversation, find the first buyer message and the first
 *      seller reply after it (if any).
 *   3. Compute the gap in minutes between each (buyer_msg, seller_reply) pair.
 *   4. Take the median across all pairs for that seller (more robust than
 *      mean — resistant to outliers from holidays / long absences).
 *   5. Write the result to user_profiles.response_time_minutes.
 *   6. NULL out sellers who have had no new buyer messages in 90 days
 *      (stale data is worse than no data for trust display purposes).
 *
 * Reference: docs/epics/E04-messaging.md §Seller Response Time
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Only consider conversations within this window — avoids skewing median
// with ancient response patterns that no longer reflect seller behaviour.
const LOOKBACK_DAYS = 90;

// Sellers with fewer than this many (buyer_msg, reply) pairs are excluded
// from update — too little signal to show a meaningful stat.
const MIN_RESPONSE_PAIRS = 3;

// Batch size for .in() filters — keeps PostgREST URLs under length limits.
const QUERY_BATCH = 100;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string;
  created_at: string;
}

interface ConversationRow {
  id: string;
  seller_id: string; // resolved via listings join
}

interface SellerResult {
  seller_id: string;
  response_time_minutes: number;
  pair_count: number;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

/** Fetch in batches to avoid PostgREST URL length limits on .in() filters. */
async function fetchMessagesBatched(
  supabase: ReturnType<typeof createClient>,
  convIds: string[],
): Promise<MessageRow[]> {
  const all: MessageRow[] = [];
  for (let i = 0; i < convIds.length; i += QUERY_BATCH) {
    const batch = convIds.slice(i, i + QUERY_BATCH);
    const { data, error } = await supabase
      .from("messages")
      .select("id, conversation_id, sender_id, created_at")
      .in("conversation_id", batch)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`messages batch ${i}: ${error.message}`);
    if (data) all.push(...(data as MessageRow[]));
  }
  return all;
}

// ---------------------------------------------------------------------------
// Core computation
// ---------------------------------------------------------------------------

async function computeSellerResponseTimes(
  supabase: ReturnType<typeof createClient>,
): Promise<SellerResult[]> {
  const since = new Date();
  since.setDate(since.getDate() - LOOKBACK_DAYS);

  // Fetch all conversations created within lookback window, joining to
  // listings to resolve seller_id in one query (no N+1).
  const { data: conversations, error: convError } = await supabase
    .from("conversations")
    .select("id, listings!inner(seller_id)")
    .gte("created_at", since.toISOString());

  if (convError) throw new Error(`conversations query: ${convError.message}`);
  if (!conversations || conversations.length === 0) return [];

  const convRows: ConversationRow[] = (conversations as Array<{
    id: string;
    listings: { seller_id: string };
  }>).map((c) => ({ id: c.id, seller_id: c.listings.seller_id }));

  const convIds = convRows.map((c) => c.id);

  // Fetch messages in batches to stay under URL length limits.
  const messages = await fetchMessagesBatched(supabase, convIds);
  if (messages.length === 0) return [];

  // Group messages by conversation.
  const msgsByConv = new Map<string, MessageRow[]>();
  for (const msg of messages) {
    const list = msgsByConv.get(msg.conversation_id) ?? [];
    list.push(msg);
    msgsByConv.set(msg.conversation_id, list);
  }

  // Build a map of seller_id → list of response gap minutes.
  const gapsByseller = new Map<string, number[]>();

  for (const conv of convRows) {
    const msgs = msgsByConv.get(conv.id);
    if (!msgs || msgs.length < 2) continue;

    // Walk the message list and find (first_buyer_msg, first_seller_reply)
    // pairs. Reset after each seller reply so repeated sequences are captured.
    let pendingBuyerMsg: MessageRow | null = null;

    for (const msg of msgs) {
      const isSeller = msg.sender_id === conv.seller_id;

      if (!isSeller && pendingBuyerMsg === null) {
        // First unanswered buyer message in this sequence.
        pendingBuyerMsg = msg;
      } else if (isSeller && pendingBuyerMsg !== null) {
        // Seller replied — compute gap.
        const buyerTs = new Date(pendingBuyerMsg.created_at).getTime();
        const sellerTs = new Date(msg.created_at).getTime();
        const gapMinutes = Math.round((sellerTs - buyerTs) / 60_000);

        if (gapMinutes >= 0) {
          const gaps = gapsByseller.get(conv.seller_id) ?? [];
          gaps.push(gapMinutes);
          gapsByseller.set(conv.seller_id, gaps);
        }

        // Reset so the next buyer message starts a new pair.
        pendingBuyerMsg = null;
      }
    }
  }

  // Compute median per seller and build result list.
  const results: SellerResult[] = [];

  for (const [seller_id, gaps] of gapsByseller.entries()) {
    if (gaps.length >= MIN_RESPONSE_PAIRS) {
      results.push({
        seller_id,
        response_time_minutes: Math.round(median(gaps)),
        pair_count: gaps.length,
      });
    }
  }

  return results;
}

// ---------------------------------------------------------------------------
// DB write
// ---------------------------------------------------------------------------

async function updateProfiles(
  supabase: ReturnType<typeof createClient>,
  results: SellerResult[],
): Promise<void> {
  if (results.length === 0) return;

  // Upsert in batches of 100 to stay well under Supabase payload limits.
  for (let i = 0; i < results.length; i += QUERY_BATCH) {
    const batch = results.slice(i, i + QUERY_BATCH).map((r) => ({
      id: r.seller_id,
      response_time_minutes: r.response_time_minutes,
    }));

    const { error } = await supabase
      .from("user_profiles")
      .upsert(batch, { onConflict: "id", ignoreDuplicates: false });

    if (error) throw new Error(`upsert batch ${i}: ${error.message}`);
  }
}

async function clearStaleProfiles(
  supabase: ReturnType<typeof createClient>,
  updatedSellerIds: Set<string>,
): Promise<number> {
  // Fetch all profiles that currently have a response_time_minutes value,
  // then filter out the ones we just updated — the remainder are stale.
  // This avoids a large NOT IN filter that could exceed URL length limits.
  const { data: withTime, error: selectError } = await supabase
    .from("user_profiles")
    .select("id")
    .not("response_time_minutes", "is", null);

  if (selectError) {
    console.error(`[response-time] stale select error: ${selectError.message}`);
    return 0;
  }

  if (!withTime || withTime.length === 0) return 0;

  const staleIds = (withTime as { id: string }[])
    .map((r) => r.id)
    .filter((id) => !updatedSellerIds.has(id));

  if (staleIds.length === 0) return 0;

  // Batch the NULL updates to stay under URL length limits.
  for (let i = 0; i < staleIds.length; i += QUERY_BATCH) {
    const batch = staleIds.slice(i, i + QUERY_BATCH);
    const { error } = await supabase
      .from("user_profiles")
      .update({ response_time_minutes: null })
      .in("id", batch);

    if (error) {
      console.error(`[response-time] stale clear batch ${i}: ${error.message}`);
      return i; // return count cleared so far
    }
  }

  return staleIds.length;
}

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
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const results = await computeSellerResponseTimes(supabase);
    await updateProfiles(supabase, results);

    const updatedIds = new Set(results.map((r) => r.seller_id));
    const staleCleared = updatedIds.size > 0
      ? await clearStaleProfiles(supabase, updatedIds)
      : 0;

    const summary = {
      status: "ok",
      sellers_updated: results.length,
      stale_cleared: staleCleared,
      timestamp: new Date().toISOString(),
    };

    console.log(`[response-time] ${JSON.stringify(summary)}`);
    return jsonResponse(summary);
  } catch (error) {
    const message = (error as Error).message;
    console.error(`[response-time] error: ${message}`);
    return jsonResponse({ status: "error", message }, 500);
  }
});
