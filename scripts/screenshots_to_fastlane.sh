#!/usr/bin/env bash
# screenshots_to_fastlane.sh
#
# Copies golden screenshots from test/screenshots/drivers/goldens/
# into the Fastlane directory structure expected by `deliver` (iOS) and
# `supply` (Android).
#
# Usage:
#   bash scripts/screenshots_to_fastlane.sh        # both platforms
#   bash scripts/screenshots_to_fastlane.sh ios     # iOS only
#   bash scripts/screenshots_to_fastlane.sh android # Android only
#
# Output structure:
#   fastlane/screenshots/<locale>/          (iOS — locale = en-US or nl-NL)
#   fastlane/android/screenshots/<locale>/  (Android)
#
# Only LIGHT-theme screenshots are used for store submission.
# Dark-theme goldens exist for design QA but are not uploaded.
#
# iOS device-type naming: deliver infers device type from image dimensions.
# Android screenshot naming: supply accepts any PNG name in locale dirs.

set -euo pipefail

GOLDENS_DIR="test/screenshots/drivers/goldens"
IOS_DEST="fastlane/screenshots"
ANDROID_DEST="fastlane/android/screenshots"
PLATFORM="${1:-both}"

if [[ ! -d "$GOLDENS_DIR" ]]; then
  echo "Error: goldens dir not found at $GOLDENS_DIR" >&2
  echo "Run: flutter test --update-goldens test/screenshots/drivers/ --no-pub" >&2
  exit 1
fi

# ── Locale mapping ──────────────────────────────────────────────────────────
# Golden locale suffix  → Fastlane locale dir
declare -A LOCALE_MAP=(
  ["nl_NL"]="nl-NL"
  ["en_US"]="en-US"
)

# ── iOS device mapping ──────────────────────────────────────────────────────
# Golden device suffix → iOS App Store device folder name
# (deliver uses folder names to assign device type for screenshotter)
declare -A IOS_DEVICE_MAP=(
  ["ios_67"]="iPhone 6.7\""
  ["ios_65"]="iPhone 6.5\""
  ["ios_55"]="iPhone 5.5\""
  ["ios_ipad_129"]="iPad Pro (12.9-inch)"
)

# ── Android device mapping ──────────────────────────────────────────────────
declare -A ANDROID_DEVICE_MAP=(
  ["android_phone"]="phoneScreenshots"
  ["android_tablet"]="tenInchScreenshots"
)

copy_ios() {
  echo "── Copying iOS screenshots ──────────────────────────────────────────"
  for locale_key in "${!LOCALE_MAP[@]}"; do
    locale_dir="${LOCALE_MAP[$locale_key]}"
    dest_dir="$IOS_DEST/$locale_dir"
    mkdir -p "$dest_dir"

    for device_key in "${!IOS_DEVICE_MAP[@]}"; do
      device_name="${IOS_DEVICE_MAP[$device_key]}"
      # Only light theme for store submission.
      pattern="${GOLDENS_DIR}/*_${locale_key}_light_${device_key}.png"
      for src in $pattern; do
        [[ -f "$src" ]] || continue
        screen_name=$(basename "$src" | sed "s/_${locale_key}_light_${device_key}\.png//")
        dest_name="${device_name}_${screen_name}.png"
        cp "$src" "$dest_dir/$dest_name"
        echo "  [iOS]  $locale_dir/$dest_name"
      done
    done
  done
}

copy_android() {
  echo "── Copying Android screenshots ──────────────────────────────────────"
  for locale_key in "${!LOCALE_MAP[@]}"; do
    locale_dir="${LOCALE_MAP[$locale_key]}"

    for device_key in "${!ANDROID_DEVICE_MAP[@]}"; do
      device_folder="${ANDROID_DEVICE_MAP[$device_key]}"
      dest_dir="$ANDROID_DEST/$locale_dir/$device_folder"
      mkdir -p "$dest_dir"

      pattern="${GOLDENS_DIR}/*_${locale_key}_light_${device_key}.png"
      idx=1
      for src in $pattern; do
        [[ -f "$src" ]] || continue
        screen_name=$(basename "$src" | sed "s/_${locale_key}_light_${device_key}\.png//")
        dest_name="${idx}_${screen_name}.png"
        cp "$src" "$dest_dir/$dest_name"
        echo "  [Android]  $locale_dir/$device_folder/$dest_name"
        ((idx++))
      done
    done
  done
}

case "$PLATFORM" in
  ios)     copy_ios ;;
  android) copy_android ;;
  both)    copy_ios; copy_android ;;
  *)
    echo "Usage: $0 [ios|android|both]" >&2
    exit 1
    ;;
esac

echo ""
echo "Done. Screenshots copied to:"
[[ "$PLATFORM" != "android" ]] && echo "  iOS:     $IOS_DEST/"
[[ "$PLATFORM" != "ios"     ]] && echo "  Android: $ANDROID_DEST/"
