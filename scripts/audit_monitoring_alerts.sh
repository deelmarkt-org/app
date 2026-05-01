#!/usr/bin/env bash
# B-35: Synthetic alert audit — fires one test event per production PagerDuty
# alert path so the operator can confirm each routes to the correct service +
# escalation policy + on-call rotation.
#
# Mirrors the 4 production alert call sites (verified 2026-05-01):
#   1. webhook-dlq SEV-1            (critical) — Mollie webhook 5x retry
#   2. daily-reconciliation CRIT    (critical) — ledger / Mollie mismatch
#   3. daily-reconciliation WARN    (warning)  — soft reconciliation drift
#   4. release-escrow force-release (warning)  — 90-day escrow auto-release
#
# Each event uses dedup_key="audit-<n>-YYYYMMDD" so PagerDuty auto-resolves
# and you don't double-page if the script is re-run on the same day.
#
# Usage:
#   bash scripts/audit_monitoring_alerts.sh           # dry-run (prints intended payloads)
#   bash scripts/audit_monitoring_alerts.sh --fire    # actually fires the events
#
# After firing: see docs/runbooks/RUNBOOK-monitoring-audit.md §Verification
# for the channel-by-channel checklist (Slack, PagerDuty mobile push, email).

set -euo pipefail

DRY_RUN=true
[[ "${1:-}" == "--fire" ]] && DRY_RUN=false

if [[ -z "${PAGERDUTY_ROUTING_KEY:-}" ]]; then
  echo "❌ PAGERDUTY_ROUTING_KEY not set."
  echo "   export it (or pull from .env: \`grep PAGERDUTY_ROUTING_KEY .env\`) and retry."
  exit 2
fi

DATE=$(date +%Y%m%d)
EVENTS_API="https://events.pagerduty.com/v2/enqueue"

# Each row: severity|summary|component|dedup_suffix
declare -a EVENTS=(
  "critical|[AUDIT] SEV-1: Webhook DLQ — synthetic test event|webhook-dlq|1"
  "critical|[AUDIT] Reconciliation CRITICAL — synthetic ledger drift test|daily-reconciliation|2"
  "warning|[AUDIT] Reconciliation WARNING — synthetic soft drift test|daily-reconciliation|3"
  "warning|[AUDIT] 90-day escrow force-release — synthetic test|release-escrow|4"
)

for row in "${EVENTS[@]}"; do
  IFS='|' read -r severity summary component dedup_suffix <<<"$row"
  dedup_key="audit-${dedup_suffix}-${DATE}"

  payload=$(jq -n \
    --arg key "$PAGERDUTY_ROUTING_KEY" \
    --arg sum "$summary" \
    --arg sev "$severity" \
    --arg cmp "$component" \
    --arg dk  "$dedup_key" \
    '{
      routing_key: $key,
      event_action: "trigger",
      dedup_key: $dk,
      payload: {
        summary: ("[DeelMarkt] " + $sum),
        source: "audit-monitoring-alerts.sh",
        severity: $sev,
        component: $cmp,
        custom_details: {
          synthetic: true,
          run_date: $dk,
          purpose: "B-35 monitoring audit — verify routing + escalation"
        }
      }
    }')

  echo "── ${summary}"
  echo "   severity=${severity} component=${component} dedup=${dedup_key}"

  if $DRY_RUN; then
    echo "   (dry-run; pass --fire to send)"
  else
    response=$(curl -sS -o /dev/null -w '%{http_code}' \
      -X POST "$EVENTS_API" \
      -H 'Content-Type: application/json' \
      -d "$payload")
    if [[ "$response" == "202" ]]; then
      echo "   ✅ accepted (HTTP 202)"
    else
      echo "   ❌ rejected (HTTP ${response})"
      exit 1
    fi
    sleep 2  # spread events to keep timeline readable
  fi
done

echo
if $DRY_RUN; then
  echo "Dry-run complete. Re-run with --fire to actually trigger the 4 test events."
else
  echo "🎉 4 synthetic events fired."
  echo "Now follow docs/runbooks/RUNBOOK-monitoring-audit.md §Verification."
fi
