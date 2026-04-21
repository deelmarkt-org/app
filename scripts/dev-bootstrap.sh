#!/usr/bin/env bash
# DeelMarkt — Local Stack Bootstrap
#
# Starts Supabase local (Postgres + Auth + Storage + Realtime + Edge Functions
# + Inbucket for emails), applies every migration, and prints the URLs and
# keys you need to fill in `.env`.
#
# Safe to re-run. Will not wipe data unless you pass `--reset`.
#
# Usage:
#   bash scripts/dev-bootstrap.sh           # start (or keep running) + apply migrations
#   bash scripts/dev-bootstrap.sh --reset   # drop all data and reapply migrations from scratch
#   bash scripts/dev-bootstrap.sh --stop    # stop local stack
#
# Prereqs: Docker Desktop running; Supabase CLI on PATH.
# See: docs/LOCAL-STACK.md

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}ℹ${NC}  $1"; }
ok()   { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "${RED}✗${NC}  $1"; exit 1; }

# ── Args ────────────────────────────────────────────────────────────────────
MODE="start"
for arg in "$@"; do
  case "$arg" in
    --reset) MODE="reset" ;;
    --stop)  MODE="stop" ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *) fail "Unknown argument: $arg" ;;
  esac
done

# ── Preflight ───────────────────────────────────────────────────────────────
command -v supabase >/dev/null 2>&1 || fail "Supabase CLI not installed. See docs/LOCAL-STACK.md §1."
command -v docker   >/dev/null 2>&1 || fail "Docker not installed."
docker info >/dev/null 2>&1 || fail "Docker daemon not running. Start Docker Desktop and re-run."

cd "$(dirname "$0")/.."

# ── Stop ────────────────────────────────────────────────────────────────────
if [[ "$MODE" == "stop" ]]; then
  info "Stopping local Supabase stack…"
  supabase stop
  ok "Stopped."
  exit 0
fi

# ── Start / reset ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  DeelMarkt — Local Stack Bootstrap (mode: ${MODE})${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$MODE" == "reset" ]]; then
  warn "Reset requested — all local data will be dropped."
  info "Applying every migration from supabase/migrations/…"
  supabase db reset
  ok "Database reset and migrations re-applied."
else
  if supabase status -o env 2>/dev/null | grep -q '^API_URL=http'; then
    ok "Supabase already running — keeping data."
  else
    info "Starting Supabase local stack (first run pulls ~1 GB of Docker images)…"
    supabase start
    ok "Supabase started."
  fi

  # Apply any migrations that were added since the stack was last started.
  info "Applying any new migrations…"
  supabase migration up || warn "Migration up failed — run \`supabase db reset\` if the schema is out of sync."
fi

# ── Seed ────────────────────────────────────────────────────────────────────
# Seeds are applied natively by the Supabase CLI during `db reset` and the
# first `start`, via `sql_paths = ["./seeds/*.sql"]` in supabase/config.toml.
# No psql required here — the CLI uses its bundled postgres internally. Just
# report what's in scope so the dev knows what ran (or what's missing).
if compgen -G "supabase/seeds/*.sql" >/dev/null; then
  info "Seed files present — applied by Supabase CLI automatically:"
  for seed in supabase/seeds/*.sql; do
    ok "  $(basename "$seed")"
  done
else
  warn "No seed files in supabase/seeds/ — the DB is empty. See docs/LOCAL-STACK.md."
fi

# ── Output ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Local stack is up.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
supabase status
echo ""
echo "━━ Ready-to-paste .env values ━━"
supabase status -o env | grep -E '^(ANON_KEY|API_URL|DB_URL)=' | sed \
  -e 's/^ANON_KEY=/SUPABASE_ANON_PUBLIC=/' \
  -e 's/^API_URL=/SUPABASE_URL=/' \
  -e 's/^DB_URL=/# DB (for psql\/Studio only): /'
echo ""
echo "Next steps:"
echo "  1. Paste the SUPABASE_* lines above into your .env, then:"
echo "       flutter pub run build_runner build --delete-conflicting-outputs"
echo "  2. Open http://localhost:54323  (Studio — DB browser)"
echo "  3. Open http://localhost:54324  (Inbucket — auth emails)"
echo "  4. flutter run"
echo ""
echo "See docs/LOCAL-STACK.md for troubleshooting and ngrok/Mollie/Firebase tips."
