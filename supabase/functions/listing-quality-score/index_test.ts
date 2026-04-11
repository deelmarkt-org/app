/**
 * Handler-contract tests for R-26 listing-quality-score.
 *
 * Importing index.ts directly would trigger Deno.serve at module load,
 * so the Zod schema is redeclared inline — same pattern as
 * scam-detection/index_test.ts. Scoring logic is covered in
 * scoring_engine_test.ts.
 */

import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

const DraftSchema = z.object({
  photo_count: z.number().int().min(0).max(12),
  title: z.string().max(200),
  description: z.string().max(5000),
  price_cents: z.number().int().min(0).max(100_000_000),
  category_l2_id: z.string().uuid().nullable(),
  condition: z.string().min(1).max(50).nullable(),
});

describe("DraftSchema", () => {
  it("accepts a complete draft with null optionals", () => {
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: null,
      condition: null,
    });
    assert(result.success);
  });

  it("rejects a photo_count over 12", () => {
    const result = DraftSchema.safeParse({
      photo_count: 13,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: null,
      condition: null,
    });
    assert(!result.success);
  });

  it("rejects a negative price", () => {
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: -1,
      category_l2_id: null,
      condition: null,
    });
    assert(!result.success);
  });

  it("rejects a price over the 1M EUR cap", () => {
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: 100_000_001,
      category_l2_id: null,
      condition: null,
    });
    assert(!result.success);
  });

  it("rejects a non-uuid category_l2_id", () => {
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: "not-a-uuid",
      condition: null,
    });
    assert(!result.success);
  });

  it("rejects a non-integer photo_count", () => {
    const result = DraftSchema.safeParse({
      photo_count: 2.5,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: null,
      condition: null,
    });
    assert(!result.success);
  });

  it("rejects an empty-string condition (.min(1))", () => {
    // Regression test for the Dart↔TS scoring alignment on PR #105:
    // the scorer now checks `condition !== null` only, so Zod must
    // guard against empty strings reaching the scoring engine.
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: null,
      condition: "",
    });
    assert(!result.success);
  });

  it("accepts a null condition (nullable after .min(1))", () => {
    // The .min(1) applies only when the value is a string; null is
    // still allowed because the field is .nullable().
    const result = DraftSchema.safeParse({
      photo_count: 3,
      title: "Test",
      description: "Body",
      price_cents: 100,
      category_l2_id: null,
      condition: null,
    });
    assert(result.success);
  });
});
