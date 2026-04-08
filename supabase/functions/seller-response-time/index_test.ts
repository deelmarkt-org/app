import {
  assertEquals,
  assertAlmostEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";

// ---------------------------------------------------------------------------
// Inline copies of pure helpers from index.ts
// (avoids Deno.serve / Deno.env side-effects at module scope)
// ---------------------------------------------------------------------------

function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string;
  sent_at: string;
}

interface ConversationRow {
  id: string;
  seller_id: string;
}

/** Extract (buyer_msg, seller_reply) gap minutes from a single conversation. */
function computeGapsForConversation(
  msgs: MessageRow[],
  conv: ConversationRow,
): number[] {
  const gaps: number[] = [];
  let pendingBuyerMsg: MessageRow | null = null;

  const sorted = [...msgs].sort(
    (a, b) => new Date(a.sent_at).getTime() - new Date(b.sent_at).getTime(),
  );

  for (const msg of sorted) {
    const isSeller = msg.sender_id === conv.seller_id;

    if (!isSeller && pendingBuyerMsg === null) {
      pendingBuyerMsg = msg;
    } else if (isSeller && pendingBuyerMsg !== null) {
      const buyerTs = new Date(pendingBuyerMsg.sent_at).getTime();
      const sellerTs = new Date(msg.sent_at).getTime();
      const gapMinutes = Math.round((sellerTs - buyerTs) / 60_000);
      if (gapMinutes >= 0) gaps.push(gapMinutes);
      pendingBuyerMsg = null;
    }
  }

  return gaps;
}

// ---------------------------------------------------------------------------
// HTTP-layer handler (mirrors index.ts handler, decoupled from Supabase)
// ---------------------------------------------------------------------------

async function handleRequest(
  req: Request,
  serviceRoleKey: string,
  computeFn: () => Promise<{ sellers_updated: number; stale_cleared: number }>,
): Promise<Response> {
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace("Bearer ", "");
  if (token !== serviceRoleKey) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { sellers_updated, stale_cleared } = await computeFn();
    return new Response(
      JSON.stringify({
        status: "ok",
        sellers_updated,
        stale_cleared,
        timestamp: new Date().toISOString(),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ status: "error", message: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
}

// ---------------------------------------------------------------------------
// Tests — median helper
// ---------------------------------------------------------------------------

describe("median()", () => {
  it("returns the middle value for odd-length array", () => {
    assertEquals(median([10, 30, 20]), 20);
  });

  it("returns the average of two middle values for even-length array", () => {
    assertEquals(median([10, 20, 30, 40]), 25);
  });

  it("handles single element", () => {
    assertEquals(median([42]), 42);
  });

  it("handles two elements", () => {
    assertEquals(median([10, 30]), 20);
  });

  it("is not affected by input order", () => {
    assertEquals(median([50, 10, 30, 20, 40]), 30);
  });
});

// ---------------------------------------------------------------------------
// Tests — gap computation
// ---------------------------------------------------------------------------

describe("computeGapsForConversation()", () => {
  const sellerId = "seller-1";
  const buyerId = "buyer-1";
  const convId = "conv-1";

  function makeMsg(
    id: string,
    senderId: string,
    minutesOffset: number,
  ): MessageRow {
    const base = new Date("2026-04-01T10:00:00Z");
    base.setMinutes(base.getMinutes() + minutesOffset);
    return {
      id,
      conversation_id: convId,
      sender_id: senderId,
      sent_at: base.toISOString(),
    };
  }

  const conv: ConversationRow = { id: convId, seller_id: sellerId };

  it("computes a single gap correctly", () => {
    const msgs = [
      makeMsg("m1", buyerId, 0),  // buyer at t+0
      makeMsg("m2", sellerId, 30), // seller at t+30 → 30 min gap
    ];
    assertEquals(computeGapsForConversation(msgs, conv), [30]);
  });

  it("captures multiple (buyer_msg, reply) pairs in sequence", () => {
    const msgs = [
      makeMsg("m1", buyerId, 0),   // buyer
      makeMsg("m2", sellerId, 15), // seller → 15 min
      makeMsg("m3", buyerId, 30),  // buyer again
      makeMsg("m4", sellerId, 60), // seller → 30 min
    ];
    assertEquals(computeGapsForConversation(msgs, conv), [15, 30]);
  });

  it("ignores unanswered buyer messages at end of conversation", () => {
    const msgs = [
      makeMsg("m1", buyerId, 0),
      makeMsg("m2", sellerId, 10), // answered
      makeMsg("m3", buyerId, 20),  // not yet answered
    ];
    assertEquals(computeGapsForConversation(msgs, conv), [10]);
  });

  it("ignores seller messages with no preceding buyer message", () => {
    const msgs = [
      makeMsg("m1", sellerId, 0), // seller opens — no gap
      makeMsg("m2", buyerId, 10),
      makeMsg("m3", sellerId, 25), // gap = 15 min
    ];
    assertEquals(computeGapsForConversation(msgs, conv), [15]);
  });

  it("returns empty array when seller never replies", () => {
    const msgs = [
      makeMsg("m1", buyerId, 0),
      makeMsg("m2", buyerId, 5),
    ];
    assertEquals(computeGapsForConversation(msgs, conv), []);
  });

  it("returns empty array for empty message list", () => {
    assertEquals(computeGapsForConversation([], conv), []);
  });

  it("is resilient to out-of-order input — sorts by sent_at", () => {
    const msgs = [
      makeMsg("m2", sellerId, 45), // arrives first in array but is later
      makeMsg("m1", buyerId, 0),
    ];
    assertEquals(computeGapsForConversation(msgs, conv), [45]);
  });
});

// ---------------------------------------------------------------------------
// Tests — HTTP layer
// ---------------------------------------------------------------------------

describe("HTTP handler", () => {
  const SERVICE_KEY = "test-service-role-key"; // pragma: allowlist secret
  const authHeaders = { Authorization: `Bearer ${SERVICE_KEY}` };

  it("returns 200 ok with summary on success", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "POST",
      headers: authHeaders,
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.resolve({ sellers_updated: 5, stale_cleared: 1 }),
    );
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "ok");
    assertEquals(body.sellers_updated, 5);
    assertEquals(body.stale_cleared, 1);
  });

  it("returns 401 when Authorization header is missing", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "POST",
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.resolve({ sellers_updated: 0, stale_cleared: 0 }),
    );
    assertEquals(res.status, 401);
    const body = await res.json();
    assertEquals(body.error, "Unauthorized");
  });

  it("returns 401 when token is wrong", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "POST",
      headers: { Authorization: "Bearer wrong-key" },
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.resolve({ sellers_updated: 0, stale_cleared: 0 }),
    );
    assertEquals(res.status, 401);
  });

  it("returns 405 for non-GET/POST method", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "DELETE",
      headers: authHeaders,
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.resolve({ sellers_updated: 0, stale_cleared: 0 }),
    );
    assertEquals(res.status, 405);
  });

  it("returns 500 when compute throws", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "POST",
      headers: authHeaders,
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.reject(new Error("DB connection failed")),
    );
    assertEquals(res.status, 500);
    const body = await res.json();
    assertEquals(body.status, "error");
    assertEquals(body.message, "DB connection failed");
  });

  it("accepts GET requests (for manual cron trigger testing)", async () => {
    const req = new Request("http://localhost/seller-response-time", {
      method: "GET",
      headers: authHeaders,
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.resolve({ sellers_updated: 0, stale_cleared: 0 }),
    );
    assertEquals(res.status, 200);
  });
});
