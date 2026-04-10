#!/usr/bin/env bash
# Quality score parity check — enforces that the Dart source of truth in
# lib/core/constants.dart stays in lock-step with the TypeScript mirror in
# supabase/functions/_shared/quality_score_weights.ts.
#
# Invoked by pre-commit when either file changes. If the two disagree on
# any weight or threshold, the hook fails with a diff so you know which
# value drifted.
#
# Reference: CLAUDE.md §7.1 and docs/epics/E01-listing-management.md R-26.

set -euo pipefail

DART_FILE="lib/core/constants.dart"
TS_FILE="supabase/functions/_shared/quality_score_weights.ts"

if [[ ! -f "$DART_FILE" ]]; then
  echo "ERROR: $DART_FILE not found (run from repo root)" >&2
  exit 2
fi
if [[ ! -f "$TS_FILE" ]]; then
  echo "ERROR: $TS_FILE not found" >&2
  exit 2
fi

# Extract a named `static const int <name> = <value>;` from the Dart file,
# restricted to the ListingQualityThresholds class body (awk picks the
# stanza between the class opening brace and its closing brace).
dart_value() {
  local name="$1"
  awk -v key="$name" '
    /abstract final class ListingQualityThresholds/ { inside = 1; next }
    inside && /^}/ { inside = 0 }
    inside && $0 ~ ("static const int " key " = ") {
      match($0, /= *[0-9]+/)
      if (RSTART > 0) {
        v = substr($0, RSTART + 1, RLENGTH - 1)
        gsub(/ /, "", v)
        print v
        exit
      }
    }
  ' "$DART_FILE"
}

# Extract `export const <NAME> = <value>;` from the TS file.
ts_value() {
  local name="$1"
  awk -v key="$name" '
    $0 ~ ("export const " key " = ") {
      match($0, /= *[0-9]+/)
      if (RSTART > 0) {
        v = substr($0, RSTART + 1, RLENGTH - 1)
        gsub(/ /, "", v)
        print v
        exit
      }
    }
  ' "$TS_FILE"
}

# Each row: dart_const_name ts_const_name
# Names differ (Dart is camelCase, TS is SCREAMING_SNAKE) but the values
# must match exactly.
PAIRS=(
  "minPhotos:MIN_PHOTOS"
  "minTitleLength:MIN_TITLE_LENGTH"
  "maxTitleLength:MAX_TITLE_LENGTH"
  "minDescriptionWords:MIN_DESCRIPTION_WORDS"
  "publishThreshold:PUBLISH_THRESHOLD"
  "photosWeight:PHOTOS_WEIGHT"
  "titleWeight:TITLE_WEIGHT"
  "descriptionWeight:DESCRIPTION_WEIGHT"
  "priceWeight:PRICE_WEIGHT"
  "categoryWeight:CATEGORY_WEIGHT"
  "conditionWeight:CONDITION_WEIGHT"
)

failed=0
for pair in "${PAIRS[@]}"; do
  dart_name="${pair%%:*}"
  ts_name="${pair##*:}"
  dart_val="$(dart_value "$dart_name")"
  ts_val="$(ts_value "$ts_name")"

  if [[ -z "$dart_val" ]]; then
    echo "ERROR: '$dart_name' not found in $DART_FILE" >&2
    failed=1
    continue
  fi
  if [[ -z "$ts_val" ]]; then
    echo "ERROR: '$ts_name' not found in $TS_FILE" >&2
    failed=1
    continue
  fi
  if [[ "$dart_val" != "$ts_val" ]]; then
    echo "DRIFT: $dart_name=$dart_val in Dart but $ts_name=$ts_val in TS" >&2
    failed=1
  fi
done

# Sum of weights must equal 100 on both sides (catches single-side edits
# that keep names in sync but break the 100-point total).
weight_sum_dart=0
for w in photosWeight titleWeight descriptionWeight priceWeight categoryWeight conditionWeight; do
  weight_sum_dart=$((weight_sum_dart + $(dart_value "$w")))
done
weight_sum_ts=0
for w in PHOTOS_WEIGHT TITLE_WEIGHT DESCRIPTION_WEIGHT PRICE_WEIGHT CATEGORY_WEIGHT CONDITION_WEIGHT; do
  weight_sum_ts=$((weight_sum_ts + $(ts_value "$w")))
done

if [[ "$weight_sum_dart" -ne 100 ]]; then
  echo "ERROR: Dart weights sum to $weight_sum_dart, expected 100" >&2
  failed=1
fi
if [[ "$weight_sum_ts" -ne 100 ]]; then
  echo "ERROR: TS weights sum to $weight_sum_ts, expected 100" >&2
  failed=1
fi

if [[ $failed -ne 0 ]]; then
  echo "" >&2
  echo "Quality score parity check FAILED." >&2
  echo "Edit both files in the same commit:" >&2
  echo "  $DART_FILE" >&2
  echo "  $TS_FILE" >&2
  exit 1
fi

exit 0
