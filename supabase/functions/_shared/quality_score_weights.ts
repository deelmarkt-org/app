/**
 * Listing quality score weights and thresholds (R-26 / E01).
 *
 * These values MUST stay in sync with the Dart client source of truth in
 * lib/core/constants.dart → `ListingQualityThresholds`. The pre-commit hook
 * runs scripts/check_quality_score_parity.sh which greps both files and
 * fails the commit if any value drifts.
 *
 * When you change a value here, make the same change in constants.dart in
 * the same commit. The client uses the Dart version for real-time UI
 * feedback; this file drives the authoritative server-side publish gate.
 */

// ── Thresholds ─────────────────────────────────────────────────────────────

/** Minimum number of photos required for a quality pass. */
export const MIN_PHOTOS = 3;

/** Minimum title character count. */
export const MIN_TITLE_LENGTH = 10;

/** Maximum title character count. */
export const MAX_TITLE_LENGTH = 60;

/** Minimum word count for the description field. */
export const MIN_DESCRIPTION_WORDS = 50;

/** Minimum quality score required to publish a listing (0–100). */
export const PUBLISH_THRESHOLD = 40;

// ── Weights (must sum to 100) ──────────────────────────────────────────────

/** Points awarded when ≥MIN_PHOTOS photos are attached. */
export const PHOTOS_WEIGHT = 25;

/** Points awarded when title length is within [MIN_TITLE_LENGTH, MAX_TITLE_LENGTH]. */
export const TITLE_WEIGHT = 15;

/** Points awarded when description has ≥MIN_DESCRIPTION_WORDS. */
export const DESCRIPTION_WEIGHT = 20;

/** Points awarded when a non-zero price is set. */
export const PRICE_WEIGHT = 15;

/** Points awarded when an L2 category is selected. */
export const CATEGORY_WEIGHT = 15;

/** Points awarded when a condition is set. */
export const CONDITION_WEIGHT = 10;

// ── Field identifiers ──────────────────────────────────────────────────────

/**
 * L10n key prefixes for each scoring field, shared with the Dart client
 * so UI tips and server breakdown align.
 */
export const FIELD_NAMES = {
  photos: "sell.photos",
  title: "sell.title",
  description: "sell.description",
  price: "sell.price",
  category: "sell.category",
  condition: "sell.condition",
} as const;

/** L10n keys for per-field improvement tips (shown when a field fails). */
export const TIP_KEYS = {
  photos: "sell.tipMorePhotos",
  title: "sell.titleTip",
  description: "sell.descriptionTip",
  price: "sell.priceTip",
  category: "sell.categoryTip",
  condition: "sell.conditionTip",
} as const;
