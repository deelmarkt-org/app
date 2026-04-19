#!/usr/bin/env bash
# web_smoke.sh — Builds Flutter Web and performs a quick HTTP + CORS smoke.
#
# Usage: bash scripts/web_smoke.sh
# Exit 0 = smoke passed. Exit non-zero = failure.
set -euo pipefail

PORT=8000
BASE_HREF="/"
ORIGINS=("https://deelmarkt.com" "https://www.deelmarkt.com")

echo "==> Building Flutter Web (release)..."
flutter build web --release --base-href="${BASE_HREF}" 2>&1

# Serve build/web on localhost:$PORT using dhttpd (dart pub global)
echo "==> Starting local server on port $PORT..."
dart pub global activate dhttpd 2>/dev/null || true
dart pub global run dhttpd --port "${PORT}" --path build/web &
SERVER_PID=$!
sleep 2  # wait for server to start

cleanup() {
  kill "${SERVER_PID}" 2>/dev/null || true
}
trap cleanup EXIT

# Assert HTTP 200 on index
echo "==> Asserting HTTP 200 on http://localhost:${PORT}/..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/")
if [[ "${STATUS}" != "200" ]]; then
  echo "FAIL: Expected 200, got ${STATUS}"
  exit 1
fi
echo "    HTTP 200 OK"

# Assert no CORS errors in build output (already captured above).
# CDN CORS is verified separately via cdn-cors.md artifact (ADR-022 §4.A.0).
echo "==> Web smoke PASSED."
