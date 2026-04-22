#!/usr/bin/env bash
# DeelMarkt — tear down the local dev stack cleanly.
#
# Stops the Edge Functions serve process started by dev-up.sh, then stops
# the Supabase stack. Data persists between runs unless you pass --reset
# to dev-up.sh / dev-bootstrap.sh later.
#
# Usage: bash scripts/dev-down.sh

set -euo pipefail
cd "$(dirname "$0")/.."

FUNC_PID_FILE="/tmp/deelmarkt-functions-serve.pid"
if [[ -f "$FUNC_PID_FILE" ]] && kill -0 "$(cat "$FUNC_PID_FILE")" 2>/dev/null; then
  kill "$(cat "$FUNC_PID_FILE")" && rm -f "$FUNC_PID_FILE"
  echo "✓ Edge Functions stopped."
fi

supabase stop || true
echo "✓ Supabase stopped."
