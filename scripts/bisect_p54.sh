#!/usr/bin/env bash
#
# bisect_p54.sh — `git bisect run`-compatible test wrapper for P-54 burn-down.
#
# Usage during bisect:
#   git bisect start
#   git bisect bad <bad-commit-sha>
#   git bisect good <good-commit-sha>
#   git bisect run bash scripts/bisect_p54.sh
#
# Exit codes (per `git bisect run` contract):
#   0   = commit is GOOD
#   125 = commit cannot be tested (skip — e.g. compile failure unrelated to bug)
#   1   = commit is BAD
#   >127 reserved
#
# Reference: docs/PLAN-P54-screen-decomposition.md §13 (D9 bisect-safe commits)

set -uo pipefail

LOG_TAG="bisect_p54"

log() {
  echo "[${LOG_TAG}] $*" >&2
}

# 1. Quick compile check — if `flutter analyze` fails for unrelated reasons
#    (missing .g.dart, broken import outside scope), skip this commit.
log "Step 1/3: flutter analyze"
if ! flutter analyze --no-pub --fatal-infos > /tmp/bisect_analyze.log 2>&1; then
  if grep -qE "Undefined name '_Env'|env\.g\.dart" /tmp/bisect_analyze.log; then
    log "SKIP — env.g.dart not generated in this commit (unrelated to P-54)"
    exit 125
  fi
  log "BAD — flutter analyze failed (see /tmp/bisect_analyze.log)"
  exit 1
fi

# 2. Run the targeted test suite. Override BISECT_TEST_SCOPE to narrow:
#   BISECT_TEST_SCOPE="test/features/transaction" bash scripts/bisect_p54.sh
SCOPE="${BISECT_TEST_SCOPE:-test/}"
log "Step 2/3: flutter test (--concurrency=4) — scope: ${SCOPE}"
if ! flutter test --concurrency=4 --reporter=compact "${SCOPE}" > /tmp/bisect_test.log 2>&1; then
  log "BAD — test failed in scope ${SCOPE} (see /tmp/bisect_test.log)"
  exit 1
fi

# 3. Optional: enforce CLAUDE.md §2.1 budget check on the 9 P-54 files.
#    Disabled by default (BISECT_CHECK_LOC=1 to enable) because budget breach
#    is the *expected* state at the start of bisect (pre-decomposition).
if [[ "${BISECT_CHECK_LOC:-0}" == "1" ]]; then
  log "Step 3/3: CLAUDE.md §2.1 budget check (BISECT_CHECK_LOC=1)"
  declare -a P54_FILES=(
    "lib/features/transaction/presentation/screens/mollie_checkout_screen.dart"
    "lib/features/messages/presentation/screens/chat_thread_screen.dart"
    "lib/features/home/presentation/screens/category_detail_screen.dart"
    "lib/features/listing_detail/presentation/widgets/detail_loading_view.dart"
    "lib/features/search/presentation/widgets/search_results_view.dart"
    "lib/features/home/presentation/widgets/home_data_view.dart"
    "lib/features/listing_detail/presentation/listing_detail_screen.dart"
    "lib/features/profile/presentation/screens/appeal_screen.dart"
    "lib/features/sell/presentation/screens/listing_creation_screen.dart"
  )
  for f in "${P54_FILES[@]}"; do
    if [[ -f "${f}" ]]; then
      lines=$(wc -l < "${f}")
      if [[ ${lines} -gt 200 ]]; then
        log "BAD — ${f} is ${lines} LOC (>200 §2.1 cap)"
        exit 1
      fi
    fi
  done
fi

log "GOOD — commit passes all bisect gates"
exit 0
