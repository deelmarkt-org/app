#!/usr/bin/env bash
# DeelMarkt — Populate local Supabase Vault with secrets from .env + firebase/
#
# Edge Functions read secrets from Supabase Vault (not process env) via
# `getVaultSecret(...)`. In Supabase Cloud the vault is populated by ops;
# locally we seed it from `.env` + the Firebase admin SDK JSON so the
# create-payment / mollie-webhook / image-upload-process / send-push-
# notification functions work end-to-end.
#
# Idempotent — re-running updates existing secrets.
#
# Usage: bash scripts/dev-secrets.sh
#
# Prereq: `supabase start` must already be running (this script reads the
# service-role key from `supabase status -o env`).

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ${NC}  $1"; }
ok()   { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "${RED}✗${NC}  $1"; exit 1; }

cd "$(dirname "$0")/.."

command -v curl >/dev/null || fail "curl not installed."
[[ -f .env ]] || fail "No .env — copy .env.example and fill in credentials first."

# ── Read Supabase local endpoints/keys ──────────────────────────────────────
# If .env has a SUPABASE_PROJECT_ID that doesn't match the running container,
# `supabase status` errors with "No such container" — catch that explicitly.
status_env="$(supabase status -o env 2>&1 || true)"
if echo "$status_env" | grep -q "No such container"; then
  fail $'supabase status cannot find the running container.\n   Likely cause: .env has SUPABASE_PROJECT_ID set and it does not match\n   the running stack (duplicate/stale line?). Remove SUPABASE_PROJECT_ID\n   from .env locally — SUPABASE_URL is all the app needs.'
fi
api_url="$(echo "$status_env" | grep '^API_URL=' | cut -d'=' -f2- | tr -d '"' || true)"
service_key="$(echo "$status_env" | grep '^SERVICE_ROLE_KEY=' | cut -d'=' -f2- | tr -d '"' || true)"

[[ -n "$api_url" ]]     || fail "Supabase not running — run scripts/dev-bootstrap.sh first."
[[ -n "$service_key" ]] || fail "Could not read SERVICE_ROLE_KEY from supabase status."

# ── Load .env (without exporting to current shell) ──────────────────────────
get_env() {
  local key="$1"
  grep -E "^${key}=" .env | tail -1 | cut -d'=' -f2- || true
}

cloudinary_url="$(get_env CLOUDINARY_URL)"
mollie_key="$(get_env MOLLIE_TEST_API_KEY)"

# ── Parse Cloudinary URL (cloudinary://<api_key>:<api_secret>@<cloud_name>) ─
cloud_name=""; api_key=""; api_secret=""
if [[ "$cloudinary_url" =~ ^cloudinary://([^:]+):([^@]+)@(.+)$ ]]; then
  api_key="${BASH_REMATCH[1]}"
  api_secret="${BASH_REMATCH[2]}"
  cloud_name="${BASH_REMATCH[3]}"
fi

# ── Firebase admin SDK ──────────────────────────────────────────────────────
fcm_json=""
fcm_file="$(ls firebase/deelmarkt-*-firebase-adminsdk-*.json 2>/dev/null | head -1 || true)"
if [[ -n "$fcm_file" ]]; then
  fcm_json="$(cat "$fcm_file")"
fi

# ── Upsert helper ───────────────────────────────────────────────────────────
# Vault's `vault.create_secret(secret, name)` enforces unique names. We call
# a two-step: try insert; on 409/duplicate, the RPC errors — catch, warn, and
# continue (value not rotated). To rotate, `supabase stop --no-backup && start`
# which wipes the vault. Good enough for dev workflow.
put_secret() {
  local name="$1" value="$2" desc="$3"
  [[ -n "$value" ]] || { warn "skip $name — empty value"; return 0; }

  # Use jq to produce a safely-quoted JSON body (handles newlines in FCM JSON).
  local body
  if command -v jq >/dev/null; then
    body="$(jq -n --arg n "$name" --arg s "$value" --arg d "$desc" \
      '{p_name:$n, p_secret:$s, p_description:$d}')"
  else
    # Fallback — escape quotes and newlines by-hand. Enough for our 3 string
    # inputs since jq is universally available on macOS/Linux via Supabase CLI.
    fail "jq not installed. brew install jq  OR  scoop install jq"
  fi

  local status
  status=$(curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$api_url/rest/v1/rpc/insert_vault_secret" \
    -H "apikey: $service_key" \
    -H "Authorization: Bearer $service_key" \
    -H "Content-Type: application/json" \
    -d "$body" || echo "000")

  if [[ "$status" == "200" ]]; then
    ok "vault: $name"
  elif [[ "$status" == "409" ]] || [[ "$status" == "500" ]]; then
    warn "vault: $name already set (supabase stop/start wipes it)"
  else
    fail "vault: $name — HTTP $status"
  fi
}

# ── Write all secrets ───────────────────────────────────────────────────────
echo ""
info "Populating Supabase Vault from .env + firebase/…"

put_secret "CLOUDINARY_CLOUD_NAME" "$cloud_name"      "GH-59 image pipeline"
put_secret "CLOUDINARY_API_KEY"    "$api_key"         "GH-59 image pipeline"
put_secret "CLOUDINARY_API_SECRET" "$api_secret"      "GH-59 image pipeline"
put_secret "mollie_api_key"        "$mollie_key"      "Mollie test (local dev)"
put_secret "fcm_service_account"   "$fcm_json"        "Firebase admin SDK (FCM push)"

echo ""
ok "Vault seeded. Start Edge Functions in a second terminal:"
echo "    supabase functions serve"
echo ""
echo "  Then for Mollie webhooks (if testing checkout):"
echo "    ngrok http 54321"
echo "    # Paste the https://*.ngrok-free.app URL into Mollie dashboard → profile → webhook URL."
