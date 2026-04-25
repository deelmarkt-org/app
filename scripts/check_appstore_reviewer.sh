#!/usr/bin/env bash
# App Store reviewer demo-account healthcheck.
#
# GH #162 / Tier 2 task T7.
#
# Verifies that the App Store reviewer fixture seeded by
#   supabase/migrations/<ts>_seed_appstore_reviewer_account.sql
# is intact in the target Supabase project. Designed to run weekly via the
# `appstore-reviewer-healthcheck.yml` GitHub Actions workflow AND on demand
# from a developer machine before any TestFlight cut.
#
# Checks (each must pass — fail-closed):
#   1. is_appstore_reviewer() helper function exists
#   2. Both reviewer auth.users rows exist
#   3. Both user_profiles rows exist with kyc_level=level2
#   4. Reviewer demo listing exists, is_active=true, is_sold=false,
#      escrow_eligible=true
#   5. Reviewer demo transaction exists with status='paid'
#   6. Reviewer demo conversation has >= 2 messages
#
# Usage:
#   bash scripts/check_appstore_reviewer.sh
#
# Required env (one of):
#   SUPABASE_DB_URL                  — full PostgreSQL URL (preferred for CI)
#   SUPABASE_PROJECT_REF + SUPABASE_DB_PASSWORD
#                                    — assembled into a pooler URL (dev shorthand)
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more checks failed (script prints which)
#   2 = prerequisite missing (psql, env vars)
#
# Reference: docs/runbooks/RUNBOOK-appstore-reviewer.md

set -uo pipefail

# Sentinel UUIDs — keep in lock-step with the seed migration. Changing these
# requires re-seeding every environment AND updating the runbook.
readonly REVIEWER_SELLER_ID='aa162162-0000-0000-0000-000000000001'
readonly REVIEWER_BUYER_ID='aa162162-0000-0000-0000-000000000002'
readonly REVIEWER_LISTING_ID='aa162162-0000-0000-0000-000000000010'
readonly REVIEWER_TXN_ID='aa162162-0000-0000-0000-000000000020'
readonly REVIEWER_CONVO_ID='aa162162-0000-0000-0000-000000000030'

# ── Prerequisites ───────────────────────────────────────────────────────────

if ! command -v psql >/dev/null 2>&1; then
  echo "❌ psql not installed. Install postgresql-client (apt) or libpq (brew)."
  exit 2
fi

DB_URL="${SUPABASE_DB_URL:-}"
if [[ -z "${DB_URL}" ]]; then
  if [[ -n "${SUPABASE_PROJECT_REF:-}" && -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
    # Supabase pooler URL pattern (transaction mode, port 6543).
    DB_URL="postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"
  else
    echo "❌ Set SUPABASE_DB_URL or SUPABASE_PROJECT_REF + SUPABASE_DB_PASSWORD."
    exit 2
  fi
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

# Run a SQL query and trim whitespace. Suppresses notices and column headers.
psql_q() {
  PGOPTIONS='--client-min-messages=warning' \
    psql "${DB_URL}" -t -A -c "$1" 2>&1 | tr -d '[:space:]'
}

errors=0
checks=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  checks=$((checks + 1))
  if [[ "${actual}" == "${expected}" ]]; then
    echo "✅ ${label}"
  else
    echo "❌ ${label} — expected '${expected}', got '${actual}'"
    errors=$((errors + 1))
  fi
}

# ── Checks ──────────────────────────────────────────────────────────────────

echo "🔎 App Store reviewer healthcheck against $(echo "${DB_URL}" | sed -E 's#://[^@]+@#://***@#')"

# 1. Helper function exists.
fn_exists=$(psql_q "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_appstore_reviewer')")
assert_eq "is_appstore_reviewer() function present" "t" "${fn_exists}"

# 2. Both auth.users rows exist.
auth_count=$(psql_q "SELECT count(*) FROM auth.users WHERE id IN ('${REVIEWER_SELLER_ID}', '${REVIEWER_BUYER_ID}')")
assert_eq "auth.users rows for both reviewer accounts" "2" "${auth_count}"

# 3. Both user_profiles rows exist with kyc_level=level2.
profile_count=$(psql_q "SELECT count(*) FROM public.user_profiles WHERE id IN ('${REVIEWER_SELLER_ID}', '${REVIEWER_BUYER_ID}') AND kyc_level = 'level2'")
assert_eq "user_profiles kyc_level=level2 for both accounts" "2" "${profile_count}"

# 4. Listing is active, unsold, escrow-eligible.
listing_ok=$(psql_q "SELECT (is_active AND NOT is_sold AND escrow_eligible)::text FROM public.listings WHERE id = '${REVIEWER_LISTING_ID}'")
assert_eq "demo listing is active+unsold+escrow_eligible" "true" "${listing_ok}"

# 5. Transaction exists and status='paid'.
txn_status=$(psql_q "SELECT status::text FROM public.transactions WHERE id = '${REVIEWER_TXN_ID}'")
assert_eq "demo transaction status=paid" "paid" "${txn_status}"

# 6. Conversation has >= 2 messages.
msg_count=$(psql_q "SELECT (count(*) >= 2)::text FROM public.messages WHERE conversation_id = '${REVIEWER_CONVO_ID}'")
assert_eq "demo conversation has >= 2 messages" "true" "${msg_count}"

# ── Report ──────────────────────────────────────────────────────────────────

echo
if (( errors == 0 )); then
  echo "🎉 All ${checks} checks passed → reviewer fixture is healthy."
  exit 0
else
  echo "💥 ${errors}/${checks} check(s) failed. Re-run the seed migration or follow"
  echo "   docs/runbooks/RUNBOOK-appstore-reviewer.md §Recover."
  exit 1
fi
