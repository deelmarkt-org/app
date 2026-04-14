/**
 * Unit tests for R-30 process-search-outbox.
 *
 * Tests cover the cache key mapping logic, event classification,
 * and edge cases (malformed events, empty batches). The actual Redis
 * and Supabase calls are not tested here — those require integration
 * tests against a running instance.
 *
 * The handler uses Deno.serve which cannot be imported directly in
 * tests, so we test the pure logic functions by replicating the key
 * helpers and event-mapping logic inline.
 */

import { assert, assertEquals } from "@std/assert";
import { describe, it } from "@std/testing/bdd";

// ── Inline copies of pure helpers from index.ts ─────────────────────────
// Keep in sync manually — same pattern as image-upload-process/index_test.ts.

function listingDetailKey(listingId: string): string {
  return `listing:detail:${listingId}`;
}

function userProfileKey(sellerId: string): string {
  return `user:profile:${sellerId}`;
}

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

/**
 * Replicates the event-classification loop from the handler.
 * Returns the sets of keys to delete and whether a search bust is needed.
 */
function classifyEvents(events: OutboxRow[]): {
  detailKeys: Set<string>;
  profileKeys: Set<string>;
  needsSearchBust: boolean;
  validIds: string[];
} {
  const detailKeys = new Set<string>();
  const profileKeys = new Set<string>();
  let needsSearchBust = false;
  const validIds: string[] = [];

  for (const event of events) {
    const listingId = event.payload?.listing_id;
    const sellerId = event.payload?.seller_id;
    if (!listingId) continue;
    validIds.push(event.id);

    switch (event.event_type) {
      case "listing.sold":
      case "listing.deleted":
        detailKeys.add(listingDetailKey(listingId));
        if (sellerId) profileKeys.add(userProfileKey(sellerId));
        needsSearchBust = true;
        break;
      case "listing.created":
        if (sellerId) profileKeys.add(userProfileKey(sellerId));
        needsSearchBust = true;
        break;
      case "listing.updated":
        detailKeys.add(listingDetailKey(listingId));
        needsSearchBust = true;
        break;
    }
  }

  return { detailKeys, profileKeys, needsSearchBust, validIds };
}

// ── Tests ────────────────────────────────────────────────────────────────

describe("listingDetailKey", () => {
  it("formats the key correctly", () => {
    assertEquals(listingDetailKey("abc-123"), "listing:detail:abc-123");
  });
});

describe("userProfileKey", () => {
  it("formats the key correctly", () => {
    assertEquals(userProfileKey("user-456"), "user:profile:user-456");
  });
});

describe("classifyEvents", () => {
  const baseEvent = (
    overrides: Partial<OutboxRow> & { event_type: OutboxRow["event_type"] },
  ): OutboxRow => ({
    id: crypto.randomUUID(),
    created_at: new Date().toISOString(),
    payload: {
      listing_id: "listing-1",
      seller_id: "seller-1",
      is_active: true,
      is_sold: false,
    },
    ...overrides,
  });

  it("listing.sold → detail DEL + profile DEL + search bust", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.sold" }),
    ]);
    assert(result.detailKeys.has("listing:detail:listing-1"));
    assert(result.profileKeys.has("user:profile:seller-1"));
    assert(result.needsSearchBust);
    assertEquals(result.validIds.length, 1);
  });

  it("listing.deleted → detail DEL + profile DEL + search bust", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.deleted" }),
    ]);
    assert(result.detailKeys.has("listing:detail:listing-1"));
    assert(result.profileKeys.has("user:profile:seller-1"));
    assert(result.needsSearchBust);
  });

  it("listing.created → profile DEL + search bust (no detail DEL)", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.created" }),
    ]);
    assertEquals(result.detailKeys.size, 0);
    assert(result.profileKeys.has("user:profile:seller-1"));
    assert(result.needsSearchBust);
  });

  it("listing.updated → detail DEL + search bust + no profile DEL", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.updated" }),
    ]);
    assert(result.detailKeys.has("listing:detail:listing-1"));
    assertEquals(result.profileKeys.size, 0);
    assert(result.needsSearchBust);
  });

  it("deduplicates keys across multiple events for the same listing", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.updated" }),
      baseEvent({ event_type: "listing.sold" }),
    ]);
    // Both events target listing-1 — only one detail key.
    assertEquals(result.detailKeys.size, 1);
    assertEquals(result.validIds.length, 2);
  });

  it("deduplicates profile keys for the same seller", () => {
    const result = classifyEvents([
      baseEvent({ event_type: "listing.sold" }),
      baseEvent({
        event_type: "listing.created",
        payload: {
          listing_id: "listing-2",
          seller_id: "seller-1",
          is_active: true,
          is_sold: false,
        },
      }),
    ]);
    assertEquals(result.profileKeys.size, 1);
  });

  it("skips events with missing listing_id", () => {
    const malformed = baseEvent({ event_type: "listing.updated" });
    // deno-lint-ignore no-explicit-any
    (malformed.payload as any).listing_id = undefined;
    const result = classifyEvents([malformed]);
    assertEquals(result.validIds.length, 0);
    assertEquals(result.detailKeys.size, 0);
  });

  it("handles empty event list", () => {
    const result = classifyEvents([]);
    assertEquals(result.validIds.length, 0);
    assertEquals(result.detailKeys.size, 0);
    assertEquals(result.profileKeys.size, 0);
    assert(!result.needsSearchBust);
  });

  it("handles missing seller_id gracefully (no profile key)", () => {
    const event = baseEvent({ event_type: "listing.sold" });
    // deno-lint-ignore no-explicit-any
    (event.payload as any).seller_id = undefined;
    const result = classifyEvents([event]);
    assert(result.detailKeys.has("listing:detail:listing-1"));
    assertEquals(result.profileKeys.size, 0);
    assert(result.needsSearchBust);
  });

  it("multiple sellers → multiple profile keys", () => {
    const result = classifyEvents([
      baseEvent({
        event_type: "listing.sold",
        payload: {
          listing_id: "l-1",
          seller_id: "seller-A",
          is_active: false,
          is_sold: true,
        },
      }),
      baseEvent({
        event_type: "listing.deleted",
        payload: {
          listing_id: "l-2",
          seller_id: "seller-B",
          is_active: false,
          is_sold: false,
        },
      }),
    ]);
    assertEquals(result.profileKeys.size, 2);
    assert(result.profileKeys.has("user:profile:seller-A"));
    assert(result.profileKeys.has("user:profile:seller-B"));
  });
});
