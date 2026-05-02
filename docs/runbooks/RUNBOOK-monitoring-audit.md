# RUNBOOK — Monitoring & alert audit

> **Owner:** belengaz (DevOps)
> **Cadence:** Quarterly + on-demand after any alert routing change
> **Closes:** B-35 (sprint plan)
> **Last reviewed:** 2026-05-01

This runbook is the canonical procedure for verifying that every production
alert path is wired end-to-end: source → PagerDuty → escalation policy →
on-call mobile/email/Slack notification. Run it before every release window
and after any rotation/escalation policy change.

---

## 1. What is monitored

| # | Source | Path | Severity | Production trigger |
|---|---|---|---|---|
| 1 | `webhook-dlq` Edge Function | PagerDuty | `critical` | Mollie webhook fails 5 retries |
| 2 | `daily-reconciliation` Edge Function | PagerDuty | `critical` | Ledger ↔ Mollie mismatch (hard) |
| 3 | `daily-reconciliation` Edge Function | PagerDuty | `warning` | Soft reconciliation drift |
| 4 | `release-escrow` Edge Function | PagerDuty | `warning` | 90-day escrow force-release fired |
| 5 | Betterstack | Slack `#alerts` | varies | Uptime monitor down (3 monitors) |
| 6 | Sentry | Slack `#alerts` | varies | Mobile/web crash spike |
| 7 | GitHub Actions `redis-keepalive` | Slack | warning | Upstash keepalive 5xx |

Sources 1–4 are dual-confirmed by `scripts/audit_monitoring_alerts.sh`.
Sources 5–7 are verified by inducing a known-good failure (steps below).

---

## 2. Quarterly audit procedure

### 2a. Fire the 4 synthetic PagerDuty events

```bash
# From the project root. Source .env into the environment so the script picks
# up PAGERDUTY_ROUTING_KEY — `set -a` exports every assignment shell parses,
# and bash's dot-source unquotes values natively (handles
# PAGERDUTY_ROUTING_KEY="abc" correctly, unlike grep | cut).
set -a; . .env; set +a
bash scripts/audit_monitoring_alerts.sh           # dry-run preview
bash scripts/audit_monitoring_alerts.sh --fire    # actually trigger
```

> If you can't source the whole `.env` (e.g. it contains shell-incompatible
> entries), export just the one key with quote handling:
> ```bash
> export PAGERDUTY_ROUTING_KEY=$(awk -F= '/^PAGERDUTY_ROUTING_KEY=/{
>   sub(/^[^=]*=/,""); gsub(/^"|"$/,""); print
> }' .env)
> ```

Each event uses `dedup_key=audit-<n>-YYYYMMDD` so PagerDuty auto-merges
re-runs on the same day.

### 2b. Verification checklist (per event)

For each of the 4 events fired, confirm **all four** channels:

- [ ] **PagerDuty incident** appears in the relevant service queue with the
      `[AUDIT]` prefix and matches the expected severity.
- [ ] **Mobile push** received within 60 s on the primary on-call's phone.
- [ ] **Email** received at the on-call's PagerDuty-registered address.
- [ ] **Slack** notification posted to `#oncall` (if PD-Slack integration is
      enabled — leave unchecked if not yet configured).

After verification, **resolve all 4 incidents in one batch** in the PD UI to
clear the queue. Do not let them auto-resolve via timeout — that masks
escalation-policy bugs.

### 2c. Escalation drill (optional — every other quarter)

- [ ] Acknowledge **none** of the 4 events for 5 minutes.
- [ ] Confirm secondary on-call is paged after the configured escalation
      delay (default 5 min in the DeelMarkt policy).
- [ ] Resolve all events.

### 2d. Sources 5–7 (Betterstack / Sentry / Redis keepalive)

| Source | How to induce a test failure | Expected outcome |
|---|---|---|
| Betterstack uptime | Pause one of the 3 monitors for 2 min, then unpause | Slack `#alerts` "DOWN" then "UP" within polling interval |
| Sentry | Trigger a manual error from staging app via debug menu (or `flutter run` with `--dart-define=SENTRY_TEST=true`) | Sentry issue created + Slack `#alerts` notification within 60 s |
| `redis-keepalive` | Block the Upstash REST endpoint via Cloudflare (or temporarily rotate `UPSTASH_REDIS_REST_TOKEN` to invalid value) | Workflow run fails red, Slack notification |

---

## 3. After the audit

- File the run as a comment on the parent monitoring epic ticket with the
  PagerDuty incident IDs, dates, and any channel that didn't fire.
- If any channel failed:
  - **PagerDuty** misroute → escalate to the founder (PD billing owner) to
    rotate the integration key and re-test.
  - **Slack** misroute → check the `SLACK_WEBHOOK_URL` value in the relevant
    GitHub repo secret; rotate if compromise suspected.
  - **Mobile push** silence → on-call user must reinstall the PD app and
    re-enable critical alerts in iOS/Android settings.

---

## 4. Reference

- `scripts/audit_monitoring_alerts.sh` — synthetic event sender (this runbook §2a).
- `supabase/functions/_shared/pagerduty.ts` — production alert helper.
- Production alert call sites:
  - `supabase/functions/webhook-dlq/index.ts`
  - `supabase/functions/daily-reconciliation/index.ts`
  - `supabase/functions/release-escrow/index.ts`
