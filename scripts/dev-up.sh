#!/usr/bin/env bash
# DeelMarkt — One-shot local stack + run the app
#
# Does the full local dev setup in one command:
#   1. `supabase start` (or keep running) + apply migrations + seed DB
#   2. Populate Supabase Vault (Cloudinary, Mollie, FCM)
#   3. Start Edge Functions serve in the background
#   4. Write SUPABASE_URL + SUPABASE_ANON_PUBLIC to .env
#   5. Run build_runner to regenerate env.g.dart
#   6. `flutter run` on the device you pick (or auto-pick Chrome)
#
# Usage:
#   bash scripts/dev-up.sh                 # full flow, launches on Chrome
#   bash scripts/dev-up.sh -d macos        # any Flutter device id
#   bash scripts/dev-up.sh --no-run        # set everything up but don't launch the app
#   bash scripts/dev-up.sh --reset         # drop DB + reapply everything from scratch
#
# See docs/LOCAL-STACK.md for the manual breakdown.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ${NC}  $1"; }
ok()   { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "${RED}✗${NC}  $1"; exit 1; }

cd "$(dirname "$0")/.."

# ── Args ────────────────────────────────────────────────────────────────────
DEVICE="chrome"
NO_RUN=false
RESET_FLAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) DEVICE="$2"; shift 2 ;;
    --no-run) NO_RUN=true; shift ;;
    --reset)  RESET_FLAG="--reset"; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) fail "Unknown arg: $1" ;;
  esac
done

# ── 1. Supabase + seeds ─────────────────────────────────────────────────────
info "[1/6] Bringing up Supabase stack…"
bash scripts/dev-bootstrap.sh $RESET_FLAG

# ── 2. Vault ────────────────────────────────────────────────────────────────
info "[2/6] Seeding Vault (Cloudinary, Mollie, FCM)…"
bash scripts/dev-secrets.sh || warn "Vault seed had warnings — see above."

# ── 3. Functions serve (background) ─────────────────────────────────────────
info "[3/6] Starting Edge Functions in background…"
FUNC_LOG="/tmp/deelmarkt-functions-serve.log"
FUNC_PID_FILE="/tmp/deelmarkt-functions-serve.pid"
# Stop any previous instance we started.
if [[ -f "$FUNC_PID_FILE" ]] && kill -0 "$(cat "$FUNC_PID_FILE")" 2>/dev/null; then
  kill "$(cat "$FUNC_PID_FILE")" || true
fi
nohup supabase functions serve --no-verify-jwt >"$FUNC_LOG" 2>&1 &
echo $! >"$FUNC_PID_FILE"
ok "Edge Functions PID $(cat "$FUNC_PID_FILE") — tail: $FUNC_LOG"

# ── 4. .env — write local SUPABASE_URL + ANON ───────────────────────────────
info "[4/6] Updating .env with local Supabase URL + anon key…"
status_env="$(supabase status -o env)"
anon_key="$(echo "$status_env" | grep '^ANON_KEY=' | cut -d'=' -f2- | tr -d '"')"

# Backup .env once per session (memory: never overwrite without backup).
if [[ ! -f .env.backup ]] || [[ .env -nt .env.backup ]]; then
  cp .env .env.backup
  ok ".env backed up → .env.backup"
fi

# Upsert SUPABASE_URL + SUPABASE_ANON_PUBLIC (preserve everything else).
python3 - <<PY
import re, pathlib
p = pathlib.Path('.env')
text = p.read_text()
def upsert(body, key, val):
    pattern = re.compile(rf'^{re.escape(key)}=.*$', re.MULTILINE)
    line = f'{key}={val}'
    if pattern.search(body):
        return pattern.sub(line, body)
    return body.rstrip() + '\n' + line + '\n'
text = upsert(text, 'SUPABASE_URL', 'http://127.0.0.1:54321')
text = upsert(text, 'SUPABASE_ANON_PUBLIC', '$anon_key')
p.write_text(text)
print('.env updated')
PY

# ── 5. build_runner ─────────────────────────────────────────────────────────
info "[5/6] Regenerating env.g.dart…"
flutter pub run build_runner build --delete-conflicting-outputs >/dev/null || \
  warn "build_runner returned non-zero — check output above."
ok "env.g.dart regenerated."

# ── 6. Flutter run ──────────────────────────────────────────────────────────
echo ""
ok "Local stack ready. Useful URLs:"
echo "    Studio (DB):   http://localhost:54323"
echo "    Inbucket:      http://localhost:54324"
echo "    Edge logs:     tail -f $FUNC_LOG"
echo ""
echo "  Seeded login: buyer-l2@deelmarkt.test / Password123!  (see supabase/seeds/01_users.sql)"
echo ""

if [[ "$NO_RUN" == "true" ]]; then
  echo "  Skipping flutter run (--no-run). When ready: flutter run -d $DEVICE"
  echo "  Tear down:   supabase stop && kill \$(cat $FUNC_PID_FILE)"
  exit 0
fi

info "[6/6] flutter run -d $DEVICE  (Ctrl-C to stop the app, then \`supabase stop\` to tear down)"
echo ""
exec flutter run -d "$DEVICE"
