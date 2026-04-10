/**
 * Pure scoring logic for R-26 `listing-quality-score`.
 *
 * Exported separately from index.ts so it can be unit-tested without
 * importing the Deno.serve HTTP runtime.
 */

import {
  CATEGORY_WEIGHT,
  CONDITION_WEIGHT,
  DESCRIPTION_WEIGHT,
  FIELD_NAMES,
  MAX_TITLE_LENGTH,
  MIN_DESCRIPTION_WORDS,
  MIN_PHOTOS,
  MIN_TITLE_LENGTH,
  PHOTOS_WEIGHT,
  PRICE_WEIGHT,
  PUBLISH_THRESHOLD,
  TIP_KEYS,
  TITLE_WEIGHT,
} from "../_shared/quality_score_weights.ts";

/** Listing draft fields needed to compute a quality score. */
export interface ListingDraft {
  photo_count: number;
  title: string;
  description: string;
  price_cents: number;
  category_l2_id: string | null;
  condition: string | null;
}

/** Per-field contribution to the total score. */
export interface ScoreField {
  /** L10n key prefix (e.g. "sell.photos") — matches Dart `QualityScoreField.name`. */
  name: string;
  /** Points earned (0 or maxPoints — fields are pass/fail). */
  points: number;
  /** Maximum points this field can earn. */
  max_points: number;
  /** Whether this field met its quality threshold. */
  passed: boolean;
  /** L10n key for improvement tip when [passed] is false, null otherwise. */
  tip_key: string | null;
}

/** Full scoring result returned by the EF. */
export interface ScoreResult {
  score: number;
  can_publish: boolean;
  breakdown: ScoreField[];
}

/**
 * Splits the input on whitespace and returns the count of non-empty tokens.
 *
 * Mirrors `qualityWordCount` in
 * lib/features/sell/domain/usecases/quality_score_helpers.dart.
 */
export function wordCount(text: string): number {
  return text.trim().split(/\s+/).filter((w) => w.length > 0).length;
}

/** Builds a single field result — the pure pass/fail helper used throughout. */
function field(
  name: string,
  passed: boolean,
  maxPoints: number,
  tipKey: string,
): ScoreField {
  return {
    name,
    points: passed ? maxPoints : 0,
    max_points: maxPoints,
    passed,
    tip_key: passed ? null : tipKey,
  };
}

/**
 * Computes the authoritative quality score for a listing draft.
 *
 * This MUST stay in sync with the Dart `CalculateQualityScoreUseCase` at
 * lib/features/sell/domain/usecases/calculate_quality_score_usecase.dart.
 * Parity is enforced by scripts/check_quality_score_parity.sh.
 */
export function calculateQualityScore(draft: ListingDraft): ScoreResult {
  const descriptionWordCount = wordCount(draft.description);

  const breakdown: ScoreField[] = [
    field(
      FIELD_NAMES.photos,
      draft.photo_count >= MIN_PHOTOS,
      PHOTOS_WEIGHT,
      TIP_KEYS.photos,
    ),
    field(
      FIELD_NAMES.title,
      draft.title.length >= MIN_TITLE_LENGTH &&
        draft.title.length <= MAX_TITLE_LENGTH,
      TITLE_WEIGHT,
      TIP_KEYS.title,
    ),
    field(
      FIELD_NAMES.description,
      descriptionWordCount >= MIN_DESCRIPTION_WORDS,
      DESCRIPTION_WEIGHT,
      TIP_KEYS.description,
    ),
    field(
      FIELD_NAMES.price,
      draft.price_cents > 0,
      PRICE_WEIGHT,
      TIP_KEYS.price,
    ),
    field(
      FIELD_NAMES.category,
      draft.category_l2_id !== null && draft.category_l2_id.length > 0,
      CATEGORY_WEIGHT,
      TIP_KEYS.category,
    ),
    field(
      FIELD_NAMES.condition,
      draft.condition !== null && draft.condition.length > 0,
      CONDITION_WEIGHT,
      TIP_KEYS.condition,
    ),
  ];

  const score = breakdown.reduce((sum, f) => sum + f.points, 0);

  return {
    score,
    can_publish: score >= PUBLISH_THRESHOLD,
    breakdown,
  };
}
