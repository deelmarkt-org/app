#!/usr/bin/env bash
# Measure Flutter web release bundle sizes and emit a markdown table.
#
# Usage:
#   bash scripts/measure_web_bundle.sh           # measures existing build/web/
#   bash scripts/measure_web_bundle.sh --build   # runs `flutter build web --release` first
#
# Output is markdown — paste into PR descriptions or commit to
# docs/observability/web-perf-baseline.md to track the bundle baseline
# over time.
#
# Owner: pizmam (P-45). See docs/observability/web-perf-baseline.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$ROOT/build/web"

if [[ "${1:-}" == "--build" ]]; then
  echo "==> flutter build web --release" >&2
  cd "$ROOT"
  flutter build web --release --no-tree-shake-icons
fi

if [[ ! -d "$WEB_DIR" ]]; then
  echo "ERROR: $WEB_DIR not found. Run with --build or run 'flutter build web --release' first." >&2
  exit 1
fi

# Format bytes as human-readable using bash arithmetic (no external numfmt dep).
human() {
  local bytes="$1"
  if (( bytes >= 1048576 )); then
    awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}"
  elif (( bytes >= 1024 )); then
    awk "BEGIN {printf \"%.1f KB\", $bytes/1024}"
  else
    echo "${bytes} B"
  fi
}

# Gzip a file to stdout and count bytes (production servers typically
# enforce gzip at the edge; this approximates real transfer size).
gz_size() {
  if [[ ! -f "$1" ]]; then echo 0; return; fi
  gzip -9 -c "$1" 2>/dev/null | wc -c | tr -d ' '
}

raw_size() {
  if [[ ! -f "$1" ]]; then echo 0; return; fi
  stat -c "%s" "$1" 2>/dev/null || stat -f "%z" "$1" 2>/dev/null || echo 0
}

print_row() {
  local label="$1" file="$2"
  local raw gz
  raw=$(raw_size "$file")
  gz=$(gz_size "$file")
  printf "| %s | %s | %s |\n" "$label" "$(human "$raw")" "$(human "$gz")"
}

cd "$WEB_DIR"
DATE=$(date -u +%Y-%m-%d)

cat <<EOF
## Web bundle baseline — $DATE

\`flutter build web --release\` (CanvasKit renderer)

| Artefact | Raw | Gzipped |
| :--- | ---: | ---: |
EOF

print_row "index.html" "index.html"
print_row "flutter_bootstrap.js" "flutter_bootstrap.js"
print_row "flutter.js" "flutter.js"
print_row "main.dart.js" "main.dart.js"
print_row "canvaskit/canvaskit.js" "canvaskit/canvaskit.js"
print_row "canvaskit/canvaskit.wasm" "canvaskit/canvaskit.wasm"
print_row "flutter_service_worker.js" "flutter_service_worker.js"

# Total directory size (raw only; gzip totals across many files isn't a
# meaningful single number for HTTP/2 streams)
total_raw=$(du -sb . 2>/dev/null | awk '{print $1}')
echo
echo "**Total \`build/web/\` raw:** $(human "$total_raw")"
echo
echo "_Critical first-paint download depends on whether CanvasKit is fetched"
echo "from gstatic.com (default) or self-hosted. See"
echo "\`docs/observability/web-perf-baseline.md\` for both totals._"
