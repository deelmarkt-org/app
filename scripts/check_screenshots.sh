#!/usr/bin/env bash
# check_screenshots.sh
#
# Validates the committed golden screenshot PNGs for:
#   1. Manifest match — every PNG in MANIFEST.txt exists, no extra PNGs
#   2. File size budget (each PNG < 8 MB — App Store / Play Console limit)
#   3. Correct dimensions per device class
#   4. PII scan via OCR (tesseract) if available
#
# Usage:
#   bash scripts/check_screenshots.sh                  # all checks
#   bash scripts/check_screenshots.sh --ocr            # + OCR PII scan (slow)
#   bash scripts/check_screenshots.sh --verbose        # verbose output
#   bash scripts/check_screenshots.sh --update-manifest
#       # Regenerate MANIFEST.txt from current goldens. Run AFTER
#       # `flutter test --update-goldens` whenever you add or remove a
#       # screenshot driver, then commit MANIFEST.txt + new PNGs together.
#
# Exit codes:
#   0  All checks passed
#   1  One or more checks failed
#
# Requirements:
#   - bash 4+, find, wc, stat, comm, sort
#   - identify (ImageMagick) for dimension check — optional
#   - tesseract for OCR PII scan — optional, only with --ocr flag
#
# Manifest design — closes GH #226
# ─────────────────────────────────
# Before #226 the gate compared `find … | wc -l` against a hardcoded
# `EXPECTED_COUNT` constant. Every PR that added a new driver had to also
# remember to bump that constant; missing the bump silently broke
# `aso-validate.yml` for every downstream PR until someone noticed (PRs
# #194, #195, #200, #213, #218 all hit this trap). The manifest approach
# trades the count for a checked-in list of expected basenames; adding a
# driver now requires committing both the new PNGs AND a regenerated
# MANIFEST.txt in the same PR, which is naturally enforceable in code
# review and produces precise add/remove diagnostics on mismatch.

set -euo pipefail

GOLDENS_DIR="test/screenshots/drivers/goldens"
MANIFEST_FILE="${GOLDENS_DIR}/MANIFEST.txt"
MAX_SIZE_MB=8

# --update-manifest takes priority over normal validation.
if [[ "${1:-}" == "--update-manifest" ]]; then
  if [[ ! -d "$GOLDENS_DIR" ]]; then
    echo "Error: $GOLDENS_DIR not found. Run flutter test --update-goldens first." >&2
    exit 1
  fi
  find "$GOLDENS_DIR" -name "*.png" -printf "%f\n" | LC_ALL=C sort > "$MANIFEST_FILE"
  count=$(wc -l < "$MANIFEST_FILE" | tr -d ' ')
  echo "✅ Regenerated $MANIFEST_FILE — $count entries."
  echo "   Commit it together with the new/removed PNGs in the same PR."
  exit 0
fi

DO_OCR="${1:-}"
VERBOSE="${2:-}"
ERRORS=0

# ── Helpers ──────────────────────────────────────────────────────────────────

err() { echo "  ❌ $*" >&2; ERRORS=$(( ERRORS + 1 )); }
warn() { echo "  ⚠️  $*" >&2; true; }
info() { if [[ "$VERBOSE" == "--verbose" ]]; then echo "  ✓  $*"; fi; }

# ── 1. Manifest match ─────────────────────────────────────────────────────────

echo "── Screenshot manifest check ───────────────────────────────────────────"
if [[ ! -d "$GOLDENS_DIR" ]]; then
  echo "Error: $GOLDENS_DIR not found. Run flutter test --update-goldens first." >&2
  exit 1
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
  err "MANIFEST_MISSING: $MANIFEST_FILE not found."
  err "  Run \`bash scripts/check_screenshots.sh --update-manifest\` and commit."
else
  actual_list=$(find "$GOLDENS_DIR" -name "*.png" -printf "%f\n" | LC_ALL=C sort)
  expected_list=$(LC_ALL=C sort "$MANIFEST_FILE")
  expected_count=$(echo "$expected_list" | wc -l | tr -d ' ')
  actual_count=$(echo "$actual_list" | wc -l | tr -d ' ')
  echo "  Manifest entries: $expected_count   Actual PNGs: $actual_count"

  added=$(LC_ALL=C comm -13 <(echo "$expected_list") <(echo "$actual_list") || true)
  missing=$(LC_ALL=C comm -23 <(echo "$expected_list") <(echo "$actual_list") || true)

  if [[ -n "$added" ]]; then
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      err "ADDED_NOT_IN_MANIFEST: $f"
    done <<< "$added"
    err "  → If this is a new driver, run \`bash scripts/check_screenshots.sh --update-manifest\`"
    err "    and commit MANIFEST.txt alongside the PNGs."
  fi
  if [[ -n "$missing" ]]; then
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      err "MISSING_FROM_GOLDENS: $f"
    done <<< "$missing"
    err "  → A manifest entry has no corresponding PNG. Either re-run"
    err "    \`flutter test --update-goldens\` or update the manifest."
  fi
  if [[ -z "$added" && -z "$missing" ]]; then
    info "Manifest matches goldens exactly."
  fi
fi

# ── 2. File size check ────────────────────────────────────────────────────────

echo "── File size check (limit: ${MAX_SIZE_MB} MB each) ────────────────────"
MAX_BYTES=$((MAX_SIZE_MB * 1024 * 1024))
oversized=0

while IFS= read -r png; do
  if [[ "$(uname)" == "Darwin" ]]; then
    size=$(stat -f %z "$png")
  else
    size=$(stat -c %s "$png")
  fi
  if [[ "$size" -gt "$MAX_BYTES" ]]; then
    size_mb=$(echo "scale=1; $size / 1048576" | bc)
    err "OVER_SIZE: $png is ${size_mb} MB (limit ${MAX_SIZE_MB} MB)"
    oversized=$(( oversized + 1 ))
  else
    info "OK: $(basename "$png") — $(( size / 1024 )) KB"
  fi
done < <(find "$GOLDENS_DIR" -name "*.png")

[[ "$oversized" -eq 0 ]] && echo "  All files within size budget." || true

# ── 3. Dimension check ────────────────────────────────────────────────────────

echo "── Dimension check (ImageMagick required) ──────────────────────────────"

if ! command -v identify &>/dev/null; then
  warn "identify (ImageMagick) not found — skipping dimension check."
  warn "Install: brew install imagemagick"
else
  # Expected logical size × DPR = physical pixels
  # Format: device_id → WxH (physical pixels)
  declare -A EXPECTED_DIMS=(
    ["ios_67"]="1290x2796"
    ["ios_65"]="1242x2688"
    ["ios_55"]="1242x2208"
    ["ios_ipad_129"]="2048x2732"
    ["android_phone"]="1080x2400"    # 412×915 × 2.625 ≈ 1081×2402 — allow ±2px
    ["android_tablet"]="1600x2560"
  )

  dim_errors=0
  while IFS= read -r png; do
    filename=$(basename "$png")
    # Extract device_id from filename pattern: {screen}_{locale}_{theme}_{device}.png
    device_id=$(echo "$filename" | sed 's/.*_\(ios_[0-9_a-z]*\|android_[a-z]*\)\.png/\1/')
    expected="${EXPECTED_DIMS[$device_id]:-unknown}"
    if [[ "$expected" == "unknown" ]]; then
      warn "Unknown device_id '$device_id' in $filename — skipping"
      continue
    fi
    actual_dim=$(identify -format "%wx%h" "$png" 2>/dev/null || echo "error")
    if [[ "$actual_dim" == "error" ]]; then
      warn "Could not read dimensions from $filename"
      continue
    fi
    if [[ "$actual_dim" != "$expected" ]]; then
      # Android dimensions may be off by a few pixels due to float rounding
      expected_w=$(echo "$expected" | cut -dx -f1)
      expected_h=$(echo "$expected" | cut -dx -f2)
      actual_w=$(echo "$actual_dim" | cut -dx -f1)
      actual_h=$(echo "$actual_dim" | cut -dx -f2)
      diff_w=$(( actual_w - expected_w ))
      diff_h=$(( actual_h - expected_h ))
      [[ $diff_w -lt 0 ]] && diff_w=$(( -diff_w ))
      [[ $diff_h -lt 0 ]] && diff_h=$(( -diff_h ))
      if [[ $diff_w -le 2 && $diff_h -le 2 ]]; then
        info "OK (±2px): $filename — ${actual_dim} vs expected ${expected}"
      else
        err "WRONG_DIM: $filename is ${actual_dim}, expected ${expected}"
        dim_errors=$(( dim_errors + 1 ))
      fi
    else
      info "OK: $filename — ${actual_dim}"
    fi
  done < <(find "$GOLDENS_DIR" -name "*.png")

  [[ "$dim_errors" -eq 0 ]] && echo "  All dimensions correct." || true
fi

# ── 4. OCR PII scan ───────────────────────────────────────────────────────────

if [[ "${1:-}" == "--ocr" ]]; then
  echo "── OCR PII scan ────────────────────────────────────────────────────────"

  if ! command -v tesseract &>/dev/null; then
    warn "tesseract not found — skipping OCR PII scan."
    warn "Install: brew install tesseract"
  else
    # PII patterns to detect
    PII_PATTERNS=(
      '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'  # email
      '\+31[0-9]{9}'                                         # Dutch phone
      'NL[0-9]{2}[A-Z]{4}[0-9]{10}'                        # IBAN
      '\b(06[-\s]?[0-9]{8})\b'                              # Dutch mobile
    )

    pii_found=0
    while IFS= read -r png; do
      text=$(tesseract "$png" stdout --psm 6 2>/dev/null || echo "")
      for pattern in "${PII_PATTERNS[@]}"; do
        match=$(echo "$text" | grep -oE "$pattern" | head -1 || true)
        if [[ -n "$match" ]]; then
          err "PII_DETECTED: $png contains pattern matching PII: '$match'"
          pii_found=$(( pii_found + 1 ))
        fi
      done
    done < <(find "$GOLDENS_DIR" -name "*.png")

    [[ "$pii_found" -eq 0 ]] && echo "  No PII detected in screenshots." || true
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo "✅  All screenshot checks passed."
  exit 0
else
  echo "❌  $ERRORS error(s) found. Fix before releasing."
  exit 1
fi
