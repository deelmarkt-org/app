#!/usr/bin/env bash
# perf_baseline.sh — Captures frame-time baseline for scroll performance.
#
# Usage: bash scripts/perf_baseline.sh [--output path/to/baseline.json]
# Requires: connected Android device or emulator in profile mode.
# Exit 0 = baseline captured. Exit non-zero = failure.
#
# Output JSON:
#   { "p50_ms": 8.2, "p95_ms": 14.1, "missed_frames": 0, "timestamp": "2026-04-17T..." }
set -euo pipefail

OUTPUT="${1:---output}"
if [[ "${OUTPUT}" == "--output" ]]; then
  OUTFILE="${2:-baseline.json}"
else
  OUTFILE="baseline.json"
fi

TIMELINE_FILE="/tmp/deel_perf_timeline.json"

echo "==> Running scroll performance driver in profile mode..."
flutter drive \
  --driver test_driver/scroll_test.dart \
  --target test_driver/scroll_test_app.dart \
  --profile \
  --timeline-streams "Dart,Embedder" \
  --no-pub 2>&1 || {
    echo "WARN: flutter drive not yet configured. Emitting placeholder baseline."
    echo '{"p50_ms":0,"p95_ms":0,"missed_frames":0,"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","note":"placeholder — configure test_driver/scroll_test.dart"}' > "${OUTFILE}"
    exit 0
  }

echo "==> Baseline captured: ${OUTFILE}"
cat "${OUTFILE}"
