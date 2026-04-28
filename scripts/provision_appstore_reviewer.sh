#!/usr/bin/env bash
# App Store reviewer auth user provisioning — Phase B turnkey for GH #162.
#
# Creates (or upserts) the two reviewer auth.users rows via the Supabase
# Auth Admin REST API, then re-applies the seed migration so the ancillary
# user_profiles / listing / transaction / conversation rows materialise.
#
# Why HTTP instead of the supabase CLI: the CLI has no `auth admin
# create-user` subcommand (verified against 2.90.0). Direct INSERT INTO
# auth.users from a SQL migration is fragile because the password hash,
# raw_user_meta, and confirmation tokens are managed by the GoTrue auth
# server, not by raw Postgres. The Admin API is the supported path.
#
# Usage:
#   bash scripts/provision_appstore_reviewer.sh
#
# Required env (export before running, e.g. via `op run -- ...`):
#   SUPABASE_PROJECT_REF        — e.g. abcdefghijklmnop (from project URL)
#   SUPABASE_SERVICE_ROLE_KEY   — service_role JWT from project settings
#                                 → API → "service_role secret".
#                                 NEVER commit this; pull from 1Password.
#   ASC_DEMO_PASSWORD           — strong reviewer-typeable password; the
#                                 same value you store in 1Password and
#                                 wire into Codemagic ASC_DEMO_PASSWORD.
#                                 If unset, a 24-char password is
#                                 generated and printed once.
#
# Optional env:
#   ASC_DEMO_USER               — reviewer email; default
#                                 appstore-reviewer@deelmarkt.com
#   REVIEWER_BUYER_EMAIL        — buyer companion email; default
#                                 appstore-reviewer-buyer@deelmarkt.com
#   SUPABASE_API_BASE_URL       — full URL override; default
#                                 https://${SUPABASE_PROJECT_REF}.supabase.co
#                                 (override only for self-hosted / dedicated)
#   SUPABASE_DB_URL             — required if you want this script to run
#                                 the seed migration too. Otherwise run
#                                 `supabase db push` separately afterwards.
#
# Exit codes:
#   0 = both users provisioned (or already existed) + seed applied (if DB_URL)
#   1 = API call failure or seed application failure
#   2 = prerequisite missing (curl, jq, env vars)
#
# Reference: docs/runbooks/RUNBOOK-appstore-reviewer.md §3 Provisioning

set -uo pipefail

# Resolve repo root from this script's location so the seed migration and
# healthcheck paths work regardless of the caller's CWD (per Gemini PR #224
# review — relative paths broke when the script was invoked from outside the
# repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Sentinel UUIDs — keep in lock-step with seed migration + healthcheck.
readonly REVIEWER_SELLER_ID='aa162162-0000-0000-0000-000000000001'
readonly REVIEWER_BUYER_ID='aa162162-0000-0000-0000-000000000002'

# Secure temp file for Admin API responses. mktemp picks a non-predictable
# name (avoids /tmp/...$$ symlink-attack class); the EXIT trap guarantees
# cleanup even if the script is interrupted (per Gemini PR #224 review).
RESP_FILE="$(mktemp)"
trap 'rm -f "$RESP_FILE"' EXIT

# ── Prerequisites ───────────────────────────────────────────────────────────

for tool in curl jq python3 mktemp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ ${tool} not installed."
    exit 2
  fi
done

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "❌ SUPABASE_PROJECT_REF not set."
  exit 2
fi
if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "❌ SUPABASE_SERVICE_ROLE_KEY not set."
  echo "   Pull from 1Password 'Supabase service_role' or"
  echo "   project dashboard → Settings → API → service_role secret."
  exit 2
fi

# Defaults.
SUPABASE_API_BASE_URL="${SUPABASE_API_BASE_URL:-https://${SUPABASE_PROJECT_REF}.supabase.co}"
ASC_DEMO_USER="${ASC_DEMO_USER:-appstore-reviewer@deelmarkt.com}"
REVIEWER_BUYER_EMAIL="${REVIEWER_BUYER_EMAIL:-appstore-reviewer-buyer@deelmarkt.com}"

# Generate a strong reviewer-typeable password if not provided.
if [[ -z "${ASC_DEMO_PASSWORD:-}" ]]; then
  echo "ℹ  ASC_DEMO_PASSWORD not set — generating one."
  ASC_DEMO_PASSWORD="$(python3 -c 'import secrets, string; alphabet = string.ascii_letters + string.digits + "-_"; print("".join(secrets.choice(alphabet) for _ in range(24)))')"
  echo "  Generated password (capture into 1Password 'App Store reviewer' NOW):"
  echo
  echo "    ${ASC_DEMO_PASSWORD}"
  echo
  echo "  This password will not be shown again."
fi

# Buyer password: deterministic-throwaway derived from seller password +
# the buyer UUID via SHA256, so re-runs converge on the same value without
# requiring the operator to track a second secret. Buyer is never typed
# by Apple's reviewer — only stored in auth.users for FK satisfaction.
REVIEWER_BUYER_PASSWORD="$(printf '%s|%s' "$ASC_DEMO_PASSWORD" "$REVIEWER_BUYER_ID" | python3 -c 'import hashlib, sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:32])')"

# ── Helpers ─────────────────────────────────────────────────────────────────

# Upsert a single auth.users row via the Admin API.
# $1 = user id (UUID), $2 = email, $3 = password
upsert_user() {
  local id="$1" email="$2" password="$3"
  local body
  body="$(jq -n \
    --arg id "$id" \
    --arg email "$email" \
    --arg password "$password" \
    '{id: $id, email: $email, password: $password, email_confirm: true}')"

  # Try POST first (creates new). If user already exists for that UUID,
  # the API returns 422; in that case fall back to PUT to rotate the
  # password instead. Body capture goes to RESP_FILE (mktemp + EXIT trap).
  local create_response
  create_response="$(curl -sS -o "$RESP_FILE" -w '%{http_code}' \
    -X POST "${SUPABASE_API_BASE_URL}/auth/v1/admin/users" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body")"

  if [[ "$create_response" == "200" || "$create_response" == "201" ]]; then
    echo "✅ Created auth.users row for ${email} (id=${id})"
    return 0
  fi

  # 422 with code "email_exists" or "user_already_exists" → upsert via PUT
  if [[ "$create_response" == "422" || "$create_response" == "409" ]]; then
    echo "ℹ  ${email} already exists — rotating password via PUT."
    local put_response
    put_response="$(curl -sS -o "$RESP_FILE" -w '%{http_code}' \
      -X PUT "${SUPABASE_API_BASE_URL}/auth/v1/admin/users/${id}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg p "$password" '{password: $p, email_confirm: true}')")"
    if [[ "$put_response" == "200" ]]; then
      echo "✅ Rotated password for ${email} (id=${id})"
      return 0
    fi
    echo "❌ PUT failed (HTTP $put_response):"
    cat "$RESP_FILE"
    return 1
  fi

  echo "❌ POST failed (HTTP $create_response):"
  cat "$RESP_FILE"
  return 1
}

# ── Provision ───────────────────────────────────────────────────────────────

echo "🔧 Provisioning App Store reviewer accounts on ${SUPABASE_API_BASE_URL}"
echo

upsert_user "$REVIEWER_SELLER_ID" "$ASC_DEMO_USER" "$ASC_DEMO_PASSWORD" || exit 1
upsert_user "$REVIEWER_BUYER_ID"  "$REVIEWER_BUYER_EMAIL" "$REVIEWER_BUYER_PASSWORD" || exit 1

# ── Seed migration ──────────────────────────────────────────────────────────

if [[ -n "${SUPABASE_DB_URL:-}" ]]; then
  echo
  echo "🌱 Re-applying seed migration so ancillary rows materialise…"
  PGOPTIONS='--client-min-messages=warning' \
    psql "${SUPABASE_DB_URL}" \
      -v ON_ERROR_STOP=1 \
      -f "${REPO_ROOT}/supabase/migrations/20260425135427_seed_appstore_reviewer_account.sql"
  echo "✅ Seed migration applied."

  echo
  echo "🩺 Running healthcheck…"
  bash "${REPO_ROOT}/scripts/check_appstore_reviewer.sh"
else
  echo
  echo "ℹ  SUPABASE_DB_URL not set — skipping seed re-apply."
  echo "   Run \`supabase db push\` (or psql -f the seed migration) next,"
  echo "   then \`bash scripts/check_appstore_reviewer.sh\` to verify."
fi

echo
echo "🎉 Phase B provisioning complete. Remaining manual steps:"
echo "   1. Save credentials to 1Password 'App Store reviewer'"
echo "      username: ${ASC_DEMO_USER}"
echo "      password: (the value above — do NOT echo it elsewhere)"
echo "   2. Set ASC_DEMO_USER + ASC_DEMO_PASSWORD as Codemagic global vars"
echo "   3. Run \`cd fastlane && bundle exec fastlane ios deliver_dry_run\`"
echo "   4. Comment + close GH #162 with the dry-run log link"
echo "   See docs/runbooks/RUNBOOK-appstore-reviewer.md §3e–§3f."
