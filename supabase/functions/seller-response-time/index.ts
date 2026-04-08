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
  response_time_minutes: number | null;
  pair_count: number;
  updated: boolean;
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

  // Fetch all messages in those conversations in one batch.
  const { data: messages, error: msgError } = await supabase
    .from("messages")
    .select("id, conversation_id, sender_id, created_at")
    .in("conversation_id", convIds)
    .order("created_at", { ascending: true });

  if (msgError) throw new Error(`messages query: ${msgError.message}`);
  if (!messages || messages.length === 0) return [];

  // Group messages by conversation.
  const msgsByConv = new Map<string, MessageRow[]>();
  for (const msg of messages as MessageRow[]) {
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
        response_time_minutes: median(gaps),
        pair_count: gaps.length,
        updated: false,
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
  const BATCH = 100;
  for (let i = 0; i < results.length; i += BATCH) {
    const batch = results.slice(i, i + BATCH).map((r) => ({
      id: r.seller_id,
      response_time_minutes: r.response_time_minutes,
    }));

    const { error } = await supabase
      .from("user_profiles")
      .upsert(batch, { onConflict: "id", ignoreDuplicates: false });

    if (error) throw new Error(`upsert batch ${i}: ${error.message}`);
  }

  // Mark all as updated in the result list (for response logging).
  for (const r of results) r.updated = true;
}

async function clearStaleProfiles(
  supabase: ReturnType<typeof createClient>,
  updatedSellerIds: string[],
): Promise<number> {
  // NULL out sellers who had an entry before but received no qualifying
  // response pairs this run (stale data removed, not left lying around).
  const { data: stale, error: selectError } = await supabase
    .from("user_profiles")
    .select("id")
    .not("response_time_minutes", "is", null)
    .not("id", "in", `(${updatedSellerIds.join(",")})`);

  if (selectError) {
    console.error(`[response-time] stale select error: ${selectError.message}`);
    return 0;
  }

  if (!stale || stale.length === 0) return 0;

  const staleIds = (stale as { id: string }[]).map((r) => r.id);

  const { error: clearError } = await supabase
    .from("user_profiles")
    .update({ response_time_minutes: null })
    .in("id", staleIds);

  if (clearError) {
    console.error(`[response-time] stale clear error: ${clearError.message}`);
    return 0;
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

    const updatedIds = results.map((r) => r.seller_id);
    const staleCleared = updatedIds.length > 0
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
