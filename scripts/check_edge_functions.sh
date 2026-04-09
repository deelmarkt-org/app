#!/usr/bin/env bash
# Edge Function quality gate — structure linting + schema cross-reference.
#
# Checks:
#   1. Structure: every function dir has deno.json, correct imports
#   2. Schema:    .select() / .order() column names validated against
#      CREATE TABLE definitions in supabase/migrations/
#   3. Patterns:  shared helpers used (verifyServiceRole, jsonResponse)
#
# Usage:
#   bash scripts/check_edge_functions.sh              # check staged .ts files
#   bash scripts/check_edge_functions.sh --all        # check all Edge Functions
#
# Exit code: 0 = pass, 1 = violations found
#
# Reference: CLAUDE.md §7.1, §9

set -uo pipefail
# Note: -e intentionally omitted — we handle errors via explicit checks.

FUNC_DIR="supabase/functions"
MIGRATION_DIR="supabase/migrations"
VIOLATIONS_FILE=$(mktemp)
SCHEMA_FILE=$(mktemp)
trap 'rm -f "$VIOLATIONS_FILE" "$SCHEMA_FILE"' EXIT

warn() { echo "  $1  $2" >> "$VIOLATIONS_FILE"; }

# ── 1. Determine which functions to check ────────────────────────────────────

FUNCTIONS=()

if [[ "${1:-}" == "--all" ]]; then
  for dir in "$FUNC_DIR"/*/; do
    name=$(basename "$dir")
    [[ "$name" == "_shared" ]] && continue
    FUNCTIONS+=("$name")
  done
else
  staged=$(git diff --cached --name-only --diff-filter=ACMR -- '*.ts' 2>/dev/null || true)
  if [[ -z "$staged" ]]; then
    echo "No staged TypeScript files to check."
    exit 0
  fi
  while IFS= read -r file; do
    if [[ "$file" == supabase/functions/* ]]; then
      name=$(echo "$file" | cut -d'/' -f3)
      [[ "$name" == "_shared" ]] && continue
      already=false
      for f in "${FUNCTIONS[@]:-}"; do [[ "$f" == "$name" ]] && already=true; done
      $already || FUNCTIONS+=("$name")
    fi
  done <<< "$staged"
fi

if [[ ${#FUNCTIONS[@]} -eq 0 ]]; then
  echo "No Edge Functions to check."
  exit 0
fi

# ── 2. Build column map from migrations ──────────────────────────────────────
# Format: one line per column: "table_name column_name"

if [[ -d "$MIGRATION_DIR" ]]; then
  for mig in "$MIGRATION_DIR"/*.sql; do
    [[ ! -f "$mig" ]] && continue
    current_table=""
    while IFS= read -r line; do
      # Match CREATE TABLE
      tbl=""
      if echo "$line" | grep -qiE 'CREATE[[:space:]]+TABLE'; then
        tbl=$(echo "$line" | sed -nE 's/.*CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?([a-z_]+\.)?([a-z_]+).*/\3/p' || true)
      fi
      if [[ -n "$tbl" ]]; then
        current_table="$tbl"
      fi

      # Match column definition — indented word followed by a type keyword or custom type name.
      # Custom types (ENUMs like transaction_status) are caught by the [a-z_]+ fallback.
      if [[ -n "$current_table" ]]; then
        if echo "$line" | grep -qE '^[[:space:]]+[a-z_]+[[:space:]]+[A-Za-z_]'; then
          col=$(echo "$line" | sed -nE 's/^[[:space:]]+([a-z_]+)[[:space:]]+.*/\1/p' || true)
          # Skip SQL keywords and non-column lines
          case "$col" in
            constraint|primary|unique|check|foreign|references|on|set|create|alter|drop|if|"") ;;
            *) echo "$current_table $col" >> "$SCHEMA_FILE" ;;
          esac
        fi
      fi

      # End of CREATE TABLE
      if [[ -n "$current_table" ]] && echo "$line" | grep -qE '^\)'; then
        current_table=""
      fi
    done < "$mig"

    # Also parse ALTER TABLE ... ADD COLUMN (handles multi-line ALTER blocks)
    alter_table=""
    while IFS= read -r line; do
      if echo "$line" | grep -qiE 'ALTER[[:space:]]+TABLE'; then
        alter_table=$(echo "$line" | sed -nE 's/.*TABLE[[:space:]]+([a-z_]+\.)?([a-z_]+).*/\2/p' || true)
      fi
      if [[ -n "$alter_table" ]] && echo "$line" | grep -qiE 'ADD[[:space:]]+(COLUMN[[:space:]]+)?[a-z_]+'; then
        col=$(echo "$line" | sed -nE 's/.*ADD[[:space:]]+(COLUMN[[:space:]]+)?([a-z_]+).*/\2/p' || true)
        if [[ -n "$col" ]]; then
          echo "$alter_table $col" >> "$SCHEMA_FILE"
        fi
      fi
      # Reset on semicolon (end of ALTER statement)
      if echo "$line" | grep -q ';'; then
        alter_table=""
      fi
    done < "$mig"
  done
fi

column_exists() {
  grep -q "^$1 $2$" "$SCHEMA_FILE" 2>/dev/null
}

# ── 3. Structure checks ─────────────────────────────────────────────────────
# Guard: FUNCTIONS may be empty on Bash 3.x (macOS default) where
# "${arr[@]}" on an empty array triggers nounset even after length check.
if [[ ${#FUNCTIONS[@]} -gt 0 ]]; then
for func in "${FUNCTIONS[@]}"; do
  func_dir="$FUNC_DIR/$func"

  # deno.json must exist
  if [[ ! -f "$func_dir/deno.json" ]]; then
    warn "MISSING_DENO_JSON" "$func_dir/ — every Edge Function must have deno.json"
  fi

  # index.ts must exist
  if [[ ! -f "$func_dir/index.ts" ]]; then
    warn "MISSING_INDEX" "$func_dir/ — no index.ts found"
    continue
  fi

  # Collect all .ts files in the function directory (index.ts + any modules)
  ts_files=()
  while IFS= read -r f; do
    # Skip test files
    [[ "$f" == *_test.ts ]] && continue
    ts_files+=("$f")
  done < <(find "$func_dir" -maxdepth 1 -name '*.ts' 2>/dev/null)

  index="$func_dir/index.ts"

  # Concatenate all non-test .ts files for rule checks (catches imports in modules)
  all_src=""
  for f in "${ts_files[@]:-}"; do
    [[ -f "$f" ]] && all_src+=$(cat "$f")$'\n'
  done

  # ── 3a. Auth: service_role functions MUST use verifyServiceRole from _shared/auth.ts
  # Condition: function creates a Supabase client with SUPABASE_SERVICE_ROLE_KEY
  # AND has no other auth mechanism (HMAC, JWT header check, anon key).
  # Functions that use JWT auth (verify_jwt = true) or HMAC (tracking-webhook)
  # are excluded — they have their own auth layer above the service_role client.
  if echo "$all_src" | grep -q 'SUPABASE_SERVICE_ROLE_KEY'; then
    has_auth=false
    # Check for known auth mechanisms
    echo "$all_src" | grep -q '_shared/auth' && has_auth=true
    echo "$all_src" | grep -q 'verifyServiceRole' && has_auth=true
    echo "$all_src" | grep -qE 'verify_jwt\s*=\s*true' && has_auth=true
    echo "$all_src" | grep -qiE 'hmac|createHmac|crypto\.subtle' && has_auth=true
    # Functions that use anon key for user-facing JWT auth (create-payment style)
    echo "$all_src" | grep -q 'SUPABASE_ANON_KEY\|getUser\|auth\.getUser' && has_auth=true
    if ! $has_auth; then
      warn "MISSING_SERVICE_ROLE_AUTH" "$func — uses SUPABASE_SERVICE_ROLE_KEY without any auth mechanism; import verifyServiceRole from _shared/auth.ts (§9, §3.3)"
    fi
  fi

  # ── 3b. Zod: Edge Functions that parse request body MUST use Zod (§9)
  # Condition: function calls req.json() to parse a request body.
  # Exception: cron/internal functions that only use GET with no body.
  if echo "$all_src" | grep -q 'req\.json()'; then
    if ! echo "$all_src" | grep -qE 'from.*zod|import.*zod|import.*{.*z.*}.*from'; then
      warn "NO_ZOD_VALIDATION" "$func — parses req.json() but does not import Zod for input validation (§9: Edge Functions use Zod)"
    fi
  fi

  # ── 3c. Shared helpers: jsonResponse must come from _shared/response.ts
  if echo "$all_src" | grep -q 'function jsonResponse' && ! echo "$all_src" | grep -q '_shared/response'; then
    warn "LOCAL_JSON_RESPONSE" "$func — defines jsonResponse locally; import from _shared/response.ts (DRY §3.3)"
  fi

  # ── 3d. Legacy check: verifyServiceRole used but not imported (backwards compat)
  if grep -q 'verifyServiceRole' "$index" && ! grep -q '_shared/auth' "$index"; then
    warn "MISSING_AUTH_IMPORT" "$func — uses verifyServiceRole but doesn't import from _shared/auth.ts"
  fi
done
fi  # end FUNCTIONS guard

# ── 4. Schema cross-reference ────────────────────────────────────────────────

schema_count=$(wc -l < "$SCHEMA_FILE" | xargs)
if [[ "$schema_count" -eq 0 ]]; then
  echo "Warning: no schema columns parsed from migrations. Skipping schema cross-reference."
else
  if [[ ${#FUNCTIONS[@]} -gt 0 ]]; then
  for func in "${FUNCTIONS[@]}"; do
    index="$FUNC_DIR/$func/index.ts"
    [[ ! -f "$index" ]] && continue

    # Flatten to single line for multi-line query parsing
    content=$(tr '\n' ' ' < "$index")

    # Extract .from("table")...select("cols") pairs using perl.
    # Known limitations (pragmatic 80/20 — catches the common cases):
    #   - Assumes .from() and .select() are on the same logical statement
    #   - Uses [^;]*? to avoid crossing statement boundaries; may fail on
    #     chained queries without semicolons or template literals with semicolons
    #   - If this script grows in complexity, consider an AST-based TS parser
    echo "$content" | perl -ne '
      while (/\.from\(['\''"](\w+)['\''"]\)[^;]*?\.select\(['\''"]([^'\''"]+)['\''"]/g) {
        print "$1|$2\n";
      }
    ' 2>/dev/null | while IFS='|' read -r table cols; do
      [[ -z "$table" || -z "$cols" ]] && continue

      # Skip if table not in our schema (might be an RPC or view)
      if ! grep -q "^$table " "$SCHEMA_FILE" 2>/dev/null; then
        continue
      fi

      # Parse individual columns
      IFS=',' read -ra parts <<< "$cols"
      for part in "${parts[@]}"; do
        part=$(echo "$part" | xargs)  # trim

        # Handle join expressions: "listings!inner(seller_id)"
        if echo "$part" | grep -qE '^[a-z_]+!'; then
          joined_table=$(echo "$part" | sed -nE 's/^([a-z_]+)!.*/\1/p' || true)
          joined_cols=$(echo "$part" | sed -nE 's/.*\(([^)]+)\).*/\1/p' || true)
          if [[ -n "$joined_cols" ]] && grep -q "^$joined_table " "$SCHEMA_FILE" 2>/dev/null; then
            IFS=',' read -ra jcols <<< "$joined_cols"
            for jcol in "${jcols[@]}"; do
              jcol=$(echo "$jcol" | xargs)
              # Handle alias: "alias:real_column"
              if [[ "$jcol" == *:* ]]; then
                real_col=$(echo "${jcol##*:}" | xargs)
              else
                real_col="$jcol"
              fi
              if ! column_exists "$joined_table" "$real_col"; then
                warn "UNKNOWN_COLUMN" "$index — .select() references $joined_table.$real_col but column not found in migrations"
              fi
            done
          fi
          continue
        fi

        # Handle alias: "alias:real_column"
        if [[ "$part" == *:* ]]; then
          real_col=$(echo "${part##*:}" | xargs)
        else
          real_col="$part"
        fi

        # Skip * and aggregates
        [[ "$real_col" == "*" ]] && continue
        [[ "$real_col" == count* ]] && continue

        if ! column_exists "$table" "$real_col"; then
          warn "UNKNOWN_COLUMN" "$index — .select() references $table.$real_col but column not found in migrations"
        fi
      done
    done || true

    # Check .order("col") calls (same regex caveats as .select() above)
    echo "$content" | perl -ne '
      while (/\.from\(['\''"](\w+)['\''"]\).*?\.order\(['\''"](\w+)['\''"]/g) {
        print "$1|$2\n";
      }
    ' 2>/dev/null | while IFS='|' read -r table col; do
      [[ -z "$table" || -z "$col" ]] && continue
      if grep -q "^$table " "$SCHEMA_FILE" 2>/dev/null && ! column_exists "$table" "$col"; then
        warn "UNKNOWN_COLUMN" "$index — .order(\"$col\") but column not found in $table"
      fi
    done || true
  done
  fi  # end FUNCTIONS guard for schema cross-reference
fi

# ── 5. Cross-language reason string alignment ───────────────────────────────
# Validates that string literals used as "reason" values in Edge Functions
# match the fromDb() mappings in lib/core/domain/entities/scam_reason.dart.
# This catches backend→frontend contract drift that no single-language
# linter can detect.

SCAM_REASON_DART="lib/core/domain/entities/scam_reason.dart"
if [[ -f "$SCAM_REASON_DART" ]]; then
  # Extract accepted reason strings from fromDb(): 'some_value' => ScamReason.x
  VALID_REASONS=$(grep -oE "'[a-z_]+'" "$SCAM_REASON_DART" | tr -d "'" | sort -u)

  if [[ ${#FUNCTIONS[@]} -gt 0 ]]; then
  for func in "${FUNCTIONS[@]}"; do
    func_dir="$FUNC_DIR/$func"

    # Only check functions that import scan_engine or reference scam detection
    all_ts=""
    for f in "$func_dir"/*.ts; do
      [[ -f "$f" && "$f" != *_test.ts ]] && all_ts+=$(cat "$f")$'\n'
    done

    # Skip functions that don't deal with scam detection
    if ! echo "$all_ts" | grep -qE 'scam|scan_engine|ScanResult|scam_confidence'; then
      continue
    fi

    # Look for REASON constant definitions: SOME_KEY: "some_value"
    # These are the authoritative reason strings output by the scan engine.
    all_reasons=$(echo "$all_ts" | grep -oE '[A-Z_]+:\s*"[a-z_]+"' | grep -oE '"[a-z_]+"' | tr -d '"' | sort -u | grep -v '^$')

    if [[ -z "$all_reasons" ]]; then
      continue
    fi

    while IFS= read -r reason; do
      if ! echo "$VALID_REASONS" | grep -qx "$reason"; then
        warn "UNKNOWN_SCAM_REASON" "$func — uses reason string '$reason' not found in ScamReason.fromDb() (scam_reason.dart)"
      fi
    done <<< "$all_reasons"
  done
  fi  # end FUNCTIONS guard
fi

# ── 6. Report ────────────────────────────────────────────────────────────────

violation_count=0
if [[ -f "$VIOLATIONS_FILE" ]]; then
  violation_count=$(wc -l < "$VIOLATIONS_FILE" | xargs)
fi

if [[ "$violation_count" -eq 0 ]]; then
  echo "Edge Function check passed (${#FUNCTIONS[@]} functions)."
  exit 0
fi

echo "Edge Function check found $violation_count issue(s):"
echo ""
cat "$VIOLATIONS_FILE"
echo ""
echo "Fix the issues above before committing."
exit 1
