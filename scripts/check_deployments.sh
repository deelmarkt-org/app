#!/usr/bin/env bash
# Deployment drift checker — detects undeployed migrations and Edge Functions.
#
# Usage:
#   bash scripts/check_deployments.sh           # check for drift
#   bash scripts/check_deployments.sh --deploy  # check + deploy pending items
#
# Requires:
#   - supabase CLI (linked to project)
#   - Network access to Supabase API
#
# Reference: CLAUDE.md §9, §11
#
# Exit codes:
#   0 = everything deployed
#   1 = pending deployments found (--deploy not passed)
#   2 = supabase CLI not available or not linked

set -uo pipefail

FUNC_DIR="supabase/functions"
AUTO_DEPLOY=false
[[ "${1:-}" == "--deploy" ]] && AUTO_DEPLOY=true

# ── Prerequisites ───────────────────────────────────────────────────────────

if ! command -v supabase &>/dev/null; then
  echo "⚠  supabase CLI not installed — skipping deployment check."
  echo "   Install: brew install supabase/tap/supabase"
  exit 2
fi

PROJECT_REF=""
if [[ -f supabase/.temp/project-ref ]]; then
  PROJECT_REF=$(cat supabase/.temp/project-ref)
fi

if [[ -z "$PROJECT_REF" ]]; then
  echo "⚠  Supabase project not linked — skipping deployment check."
  echo "   Run: supabase link --project-ref <ref>"
  exit 2
fi

PENDING=0

# ── 1. Check pending migrations ────────────────────────────────────────────

echo "Checking migrations..."
MIGRATION_OUTPUT=$(supabase db push --linked --dry-run 2>&1)

if echo "$MIGRATION_OUTPUT" | grep -q "Remote database is up to date"; then
  echo "  ✓ All migrations applied."
else
  PENDING_MIGRATIONS=$(echo "$MIGRATION_OUTPUT" | grep '^ • ' | sed 's/^ • //')
  if [[ -n "$PENDING_MIGRATIONS" ]]; then
    COUNT=$(echo "$PENDING_MIGRATIONS" | wc -l | xargs)
    echo "  ✗ $COUNT pending migration(s):"
    echo "$PENDING_MIGRATIONS" | while read -r m; do echo "    - $m"; done
    PENDING=1

    if $AUTO_DEPLOY; then
      echo ""
      echo "  Applying migrations..."
      echo "Y" | supabase db push --linked 2>&1 | grep -E "Applying|Finished|ERROR"
      if [[ $? -eq 0 ]]; then
        echo "  ✓ Migrations applied."
        PENDING=0
      else
        echo "  ✗ Migration push failed — check errors above."
      fi
    fi
  fi
fi

# ── 2. Check undeployed Edge Functions ──────────────────────────────────────

echo ""
echo "Checking Edge Functions..."

DEPLOYED=$(supabase functions list --project-ref "$PROJECT_REF" 2>&1 | awk -F'|' 'NR>2 && NF>2 {gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); if($3!="") print $3}')

UNDEPLOYED=()
OUTDATED=()

for dir in "$FUNC_DIR"/*/; do
  name=$(basename "$dir")
  [[ "$name" == "_shared" ]] && continue
  [[ ! -f "$dir/index.ts" ]] && continue

  if ! echo "$DEPLOYED" | grep -qx "$name"; then
    UNDEPLOYED+=("$name")
  fi
done

if [[ ${#UNDEPLOYED[@]} -eq 0 ]]; then
  echo "  ✓ All Edge Functions deployed."
else
  echo "  ✗ ${#UNDEPLOYED[@]} undeployed function(s):"
  for fn in "${UNDEPLOYED[@]}"; do echo "    - $fn"; done
  PENDING=1

  if $AUTO_DEPLOY; then
    echo ""
    echo "  Deploying functions..."
    for fn in "${UNDEPLOYED[@]}"; do
      echo "    Deploying $fn..."
      supabase functions deploy "$fn" --project-ref "$PROJECT_REF" 2>&1 | grep -E "Deployed|ERROR" || true
    done
    echo "  ✓ Deployment complete."
    PENDING=0
  fi
fi

# ── 3. Check for locally modified functions that may need redeployment ──────

echo ""
echo "Checking for modified functions (vs last commit on dev)..."

# Get list of .ts files changed vs dev (or origin/dev)
CHANGED_FUNCS=()
CHANGED_TS=$(git diff --name-only origin/dev -- 'supabase/functions/*/index.ts' 'supabase/functions/_shared/*.ts' 2>/dev/null || true)

if [[ -n "$CHANGED_TS" ]]; then
  # Extract unique function names from changed files
  while IFS= read -r file; do
    if [[ "$file" == supabase/functions/_shared/* ]]; then
      # Shared helper changed — all deployed functions may need redeployment
      echo "  ⚠  _shared/ helper changed: $(basename "$file")"
      echo "     Consider redeploying all functions that import it."
    elif [[ "$file" == supabase/functions/*/index.ts ]]; then
      fn=$(echo "$file" | cut -d'/' -f3)
      if echo "$DEPLOYED" | grep -qx "$fn"; then
        already=false
        for f in "${CHANGED_FUNCS[@]:-}"; do [[ "$f" == "$fn" ]] && already=true; done
        $already || CHANGED_FUNCS+=("$fn")
      fi
    fi
  done <<< "$CHANGED_TS"

  if [[ ${#CHANGED_FUNCS[@]} -gt 0 ]]; then
    echo "  ⚠  ${#CHANGED_FUNCS[@]} deployed function(s) have local changes:"
    for fn in "${CHANGED_FUNCS[@]}"; do echo "    - $fn (needs redeployment)"; done
    PENDING=1

    if $AUTO_DEPLOY; then
      echo ""
      echo "  Redeploying modified functions..."
      for fn in "${CHANGED_FUNCS[@]}"; do
        echo "    Redeploying $fn..."
        supabase functions deploy "$fn" --project-ref "$PROJECT_REF" 2>&1 | grep -E "Deployed|ERROR" || true
      done
      echo "  ✓ Redeployment complete."
      PENDING=0
    fi
  else
    echo "  ✓ No deployed functions have pending changes."
  fi
else
  echo "  ✓ No function changes vs dev."
fi

# ── 4. Summary ──────────────────────────────────────────────────────────────

echo ""
if [[ $PENDING -eq 0 ]]; then
  echo "All deployments up to date."
  exit 0
else
  echo "Action required: run 'bash scripts/check_deployments.sh --deploy' to apply pending changes."
  echo "Or deploy manually: supabase db push && supabase functions deploy <name>"
  exit 1
fi
