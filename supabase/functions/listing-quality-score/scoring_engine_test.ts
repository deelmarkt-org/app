/**
 * Unit tests for the R-26 scoring engine.
 *
 * These cover the pure function — HTTP handling is left to index_test.ts.
 * Parity with the Dart CalculateQualityScoreUseCase is enforced at
 * pre-commit time by scripts/check_quality_score_parity.sh.
 */

import {
  assertEquals,
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import {
  calculateQualityScore,
  type ListingDraft,
  wordCount,
} from "./scoring_engine.ts";
import {
  CATEGORY_WEIGHT,
  CONDITION_WEIGHT,
  DESCRIPTION_WEIGHT,
  PHOTOS_WEIGHT,
  PRICE_WEIGHT,
  PUBLISH_THRESHOLD,
  TITLE_WEIGHT,
} from "../_shared/quality_score_weights.ts";

const perfect: ListingDraft = {
  photo_count: 4,
  title: "Vintage leather satchel",
  // Description must have ≥50 words — this fixture is sized to match.
  description: Array(60).fill("word").join(" "),
  price_cents: 8500,
  category_l2_id: "11111111-1111-1111-1111-111111111111",
  condition: "good",
};

describe("wordCount", () => {
  it("handles single words", () => {
    assertStrictEquals(wordCount("hello"), 1);
  });
  it("collapses repeated whitespace", () => {
    assertStrictEquals(wordCount("  hello   world  "), 2);
  });
  it("returns zero for empty input", () => {
    assertStrictEquals(wordCount(""), 0);
  });
  it("treats tabs and newlines as whitespace", () => {
    assertStrictEquals(wordCount("a\tb\nc"), 3);
  });
});

describe("calculateQualityScore — total", () => {
  it("awards a perfect 100 for a complete draft", () => {
    const result = calculateQualityScore(perfect);
    assertStrictEquals(result.score, 100);
    assertStrictEquals(result.can_publish, true);
  });

  it("returns zero for an empty draft", () => {
    const empty: ListingDraft = {
      photo_count: 0,
      title: "",
      description: "",
      price_cents: 0,
      category_l2_id: null,
      condition: null,
    };
    const result = calculateQualityScore(empty);
    assertStrictEquals(result.score, 0);
    assertStrictEquals(result.can_publish, false);
  });

  it("allows publishing exactly at the threshold", () => {
    // Photos (25) + Title (15) = 40 — exactly at PUBLISH_THRESHOLD.
    const partial: ListingDraft = {
      ...perfect,
      description: "too short",
      price_cents: 0,
      category_l2_id: null,
      condition: null,
    };
    const result = calculateQualityScore(partial);
    assertStrictEquals(result.score, PHOTOS_WEIGHT + TITLE_WEIGHT);
    assertStrictEquals(result.score, PUBLISH_THRESHOLD);
    assertStrictEquals(result.can_publish, true);
  });

  it("blocks publishing just below the threshold", () => {
    // Photos (25) + Condition (10) = 35 — below PUBLISH_THRESHOLD.
    const partial: ListingDraft = {
      ...perfect,
      title: "short",
      description: "too short",
      price_cents: 0,
      category_l2_id: null,
    };
    const result = calculateQualityScore(partial);
    assertStrictEquals(result.score, PHOTOS_WEIGHT + CONDITION_WEIGHT);
    assertStrictEquals(result.can_publish, false);
  });
});

describe("calculateQualityScore — breakdown", () => {
  it("returns six fields in a deterministic order", () => {
    const result = calculateQualityScore(perfect);
    assertEquals(
      result.breakdown.map((f) => f.name),
      [
        "sell.photos",
        "sell.title",
        "sell.description",
        "sell.price",
        "sell.category",
        "sell.condition",
      ],
    );
  });

  it("sets tip_key to null when a field passes", () => {
    const result = calculateQualityScore(perfect);
    for (const field of result.breakdown) {
      assertStrictEquals(field.tip_key, null);
      assertStrictEquals(field.passed, true);
      assertStrictEquals(field.points, field.max_points);
    }
  });

  it("sets tip_key when a field fails", () => {
    const bad: ListingDraft = {
      ...perfect,
      photo_count: 1,
    };
    const photosField = calculateQualityScore(bad).breakdown[0];
    assertStrictEquals(photosField.passed, false);
    assertStrictEquals(photosField.points, 0);
    assertStrictEquals(photosField.tip_key, "sell.tipMorePhotos");
  });

  it("maps each field to its constant weight", () => {
    const result = calculateQualityScore(perfect);
    const byName = Object.fromEntries(
      result.breakdown.map((f) => [f.name, f.max_points]),
    );
    assertStrictEquals(byName["sell.photos"], PHOTOS_WEIGHT);
    assertStrictEquals(byName["sell.title"], TITLE_WEIGHT);
    assertStrictEquals(byName["sell.description"], DESCRIPTION_WEIGHT);
    assertStrictEquals(byName["sell.price"], PRICE_WEIGHT);
    assertStrictEquals(byName["sell.category"], CATEGORY_WEIGHT);
    assertStrictEquals(byName["sell.condition"], CONDITION_WEIGHT);
  });
});

describe("calculateQualityScore — edge cases", () => {
  it("rejects a title that is too long (>60)", () => {
    const tooLong = "a".repeat(61);
    const result = calculateQualityScore({ ...perfect, title: tooLong });
    const titleField = result.breakdown[1];
    assertStrictEquals(titleField.passed, false);
  });

  it("treats an empty-string category as passing (Zod guards upstream)", () => {
    // With the Dart↔TS scoring alignment (PR #105 review feedback),
    // the scorer checks `!== null`, matching the Dart
    // CalculateQualityScoreUseCase's `!= null`. Empty strings are
    // rejected by the Zod schema in index.ts (`category_l2_id`
    // requires `.uuid()`), so they can't reach the scoring engine in
    // practice — but this test pins the in-engine semantics so a
    // future scoring change doesn't silently drift from the Dart side.
    const result = calculateQualityScore({ ...perfect, category_l2_id: "" });
    const categoryField = result.breakdown[4];
    assertStrictEquals(categoryField.passed, true);
  });

  it("treats an empty-string condition as passing (Zod guards upstream)", () => {
    // Same alignment as category. The Zod schema uses `.min(1)` to
    // reject empty strings at the edge so the scorer never sees them.
    const result = calculateQualityScore({ ...perfect, condition: "" });
    const conditionField = result.breakdown[5];
    assertStrictEquals(conditionField.passed, true);
  });

  it("counts exactly 50 description words as passing", () => {
    const fiftyWords = Array(50).fill("word").join(" ");
    const result = calculateQualityScore({
      ...perfect,
      description: fiftyWords,
    });
    const descField = result.breakdown[2];
    assertStrictEquals(descField.passed, true);
  });
});
