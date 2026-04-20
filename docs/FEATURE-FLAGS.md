# Feature Flags Registry

> Managed via Unleash (self-hosted). All flags default **OFF** in production.
> Changes to this file must be co-reviewed by pizmam + product (for trust signals: + legal).
> Rollout procedure: dev 100% → internal 10% → beta 50% → prod 100%.

## Active Flags

| Flag key | Feature | Added | Owner | Prod status | Kill criteria |
|:---------|:--------|:------|:------|:------------|:--------------|
| `listings_escrow_badge` | EscrowBadge on listing cards (issue #59, ADR-023) | 2026-04-17 | pizmam + product | OFF (awaiting reso migration) | checkout 409 rate > 2% OR badge accuracy complaint |

## Rollout Log

| Flag | Date | Action | Approver |
|:-----|:-----|:-------|:---------|
| `listings_escrow_badge` | 2026-04-17 | Registered, default OFF | pizmam |

## Canary diagnostics

> Applies to any flag that gates a **trust signal** (escrow, KYC, verified-seller).
> Belengaz owns the rollout; pizmam owns the client instrumentation; reso owns
> the server-side telemetry. All three must sign off before each rollout stage.

### Before flipping to 10% canary

- [ ] Staging QA runbook for the flag's feature has passed (e.g.
  [`docs/runbooks/gh59-escrow-staging-verification.md`](runbooks/gh59-escrow-staging-verification.md)).
- [ ] Sentry baseline captured for the last 24h: checkout 409 rate, listing
  grid render errors, `isFeatureEnabledProvider` error count.
- [ ] Legal sign-off recorded in the Rollout Log above (trust-signal flags).

### During canary (10% → 50% → 100%)

Monitor these signals at each stage; hold ≥24h before advancing:

| Signal | Source | Threshold | Kill criterion |
|:-------|:-------|:----------|:---------------|
| Checkout 409 rate (flag mismatch) | Supabase Edge Function `create-payment-intent` logs | <2% of escrow attempts | **>2% → flip OFF** |
| Badge-accuracy Sentry events | Sentry project `deelmarkt-app`, tag `feature.listings_escrow_badge=on` | 0 user reports / 24h | **≥1 confirmed wrong badge → flip OFF** |
| Unleash toggle-fetch failures | Sentry breadcrumb `unleash.fetch_failed` | <0.1% of sessions | **>1% for >10min → flip OFF** |
| Cascade trigger p99 latency | Postgres `pg_stat_statements` for `trg_user_profiles_cascade_escrow` | <500ms | **>1s sustained → flip OFF, investigate** |

### Kill-switch procedure (seconds)

1. Unleash admin console → target environment → flag → **OFF**.
2. Post in `#product-trust` Slack with the rollout stage, trigger signal, and
   Sentry link.
3. File a fix-forward ticket (not a revert) — the server column is safe and
   the client simply stops reading it.
4. Re-enable only after root cause is fixed and staging QA re-passes.

### After 100%

- [ ] Close the linked GitHub issue (e.g. #59).
- [ ] Mark the flag `REMOVE-ON: <date+90d>` in Active Flags.
- [ ] Delete the flag (code + Unleash) after 90 days stable — stale trust-signal
  flags are a latent compliance risk.

## Governance

- All trust-signal flags (escrow, KYC badges, verification marks) require legal sign-off before exceeding 10% rollout. See `docs/COMPLIANCE.md`.
- Feature flags must NOT be used to hide incomplete features in production builds shipped to app stores — use build-time compile guards instead.
- Stale flags (> 6 months with no rollout progress) are removed in the next sprint planning.
