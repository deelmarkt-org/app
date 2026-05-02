# RUNBOOK — App Store reviewer demo account

> **Owner:** belengaz (DevOps)
> **Backup owner:** reso (DB) for fixture restoration
> **Source of truth for issue:** [#162](https://github.com/deelmarkt-org/app/issues/162)
> **Plan:** [docs/PLAN-gh162-testflight-review-info.md](../PLAN-gh162-testflight-review-info.md)
> **Last reviewed:** 2026-04-25
> **Next scheduled review:** 2026-07-25 (90-day cadence — see §Rotation)

This runbook is the **only** authoritative procedure for provisioning,
rotating, recovering, and revoking the demo account that App Store reviewers
use to evaluate DeelMarkt during App Review. Everything else (the YAML, the
Fastfile, the seed migration, the healthcheck) defers to this document.

---

## 1. Why this exists

Apple's App Review §5.1.1(v) requires us to furnish a demo account so the
reviewer can exercise iDIN-gated features (KYC, escrow, payouts) without a
Dutch bank account. Failing to provide one — or providing one that breaks
mid-review — triggers §2.1 (Performance) rejection and a cycle delay
of typically 24–72 hours per round.

The reviewer flow has three moving parts:

| Component | File / location | Owned by this runbook? |
| :--- | :--- | :--- |
| `auth.users` rows (email + password) | Supabase Auth (managed by GoTrue) | **Yes** — §Provisioning |
| `user_profiles`, `listings`, `transactions`, `conversations`, `messages` rows | Supabase DB, seeded by `supabase/migrations/20260425135427_seed_appstore_reviewer_account.sql` | Indirect — runbook triggers re-application |
| Reviewer block in App Store Connect (name, phone, email, demo creds) | `fastlane/metadata/review_information/*` + `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` env vars | **Yes** — §Credential storage |

---

## 2. Sentinel UUIDs (do **NOT** change without re-seeding every environment)

| Role | UUID | Purpose |
| :--- | :--- | :--- |
| Reviewer seller | `aa162162-0000-0000-0000-000000000001` | Primary demo login — owns the demo listing |
| Reviewer buyer | `aa162162-0000-0000-0000-000000000002` | Companion account so escrow flow has a counterparty |
| Demo listing | `aa162162-0000-0000-0000-000000000010` | Active, escrow-eligible iPhone listing |
| Demo transaction | `aa162162-0000-0000-0000-000000000020` | Status `paid` — exercises escrow-holding state |
| Demo conversation | `aa162162-0000-0000-0000-000000000030` | Buyer ⇄ seller chat for the listing |

These UUIDs are referenced by:
- The seed migration (up + down)
- `scripts/check_appstore_reviewer.sh` (healthcheck)
- The `is_appstore_reviewer(uuid)` SQL helper for analytics filtering

If you **must** change a UUID (e.g. to escape a poisoned row), update all
three locations atomically and run the down-migration first against every
environment.

---

## 3. Provisioning (one-time per environment)

### 3a. Generate credentials

```bash
# Strong, human-typeable demo password (Apple reviewers literally type this).
# 24 chars, no ambiguous characters, no shell metacharacters.
python3 -c "import secrets, string; \
  alphabet = string.ascii_letters + string.digits + '-_'; \
  print(''.join(secrets.choice(alphabet) for _ in range(24)))"
```

Suggested email: `appstore-reviewer@deelmarkt.com` (route to a shared inbox
that belengaz + reso + founder can read; needed for password recovery flows).

### 3b. Create the two `auth.users` rows via the Admin REST API

The Supabase CLI **does not** expose an `auth admin create-user` subcommand
(verified against 2.90.0). Use the Auth Admin REST API. The companion
script `scripts/provision_appstore_reviewer.sh` wraps this; run it once
with the env below and it idempotently creates (or rotates the password
on) both reviewer accounts:

```bash
# Pull SUPABASE_SERVICE_ROLE_KEY from 1Password "Supabase service_role"
# (or project dashboard → Settings → API → service_role secret).
export SUPABASE_PROJECT_REF=<your-project-ref>
export SUPABASE_SERVICE_ROLE_KEY=<service_role-jwt>
export ASC_DEMO_USER=appstore-reviewer@deelmarkt.com
export ASC_DEMO_PASSWORD="${ASC_DEMO_PASSWORD}"  # from §3a; omit to auto-generate

# Optional: also have the script run the seed migration immediately.
export SUPABASE_DB_URL=<pooler-url-from-§3d>

bash scripts/provision_appstore_reviewer.sh
```

Under the hood the script POSTs to `/auth/v1/admin/users` with the
sentinel UUIDs from §2 and `email_confirm: true`. If a user already exists
for that UUID it falls back to PUT to rotate the password (used during
§4 Rotation flow too). The buyer password is derived deterministically
from the seller password + buyer UUID via SHA256 so it never needs to be
tracked separately — the buyer account exists only to satisfy the
`transactions.buyer_id` FK.

### 3c. Apply the seed migration

```bash
# This populates user_profiles + listing + transaction + conversation +
# messages. The migration is a no-op if §3b was skipped — it logs a NOTICE
# and returns clean.
supabase db push
```

### 3d. Verify

```bash
# Set SUPABASE_DB_URL to the project's pooler URL first.
bash scripts/check_appstore_reviewer.sh
# Expected: "🎉 All 6 checks passed → reviewer fixture is healthy."
```

### 3e. Store credentials

1. **1Password** — entry name **"App Store reviewer"**, vault **"DeelMarkt — Production"**.
   Fields:
   - `username` = reviewer email from §3a
   - `password` = `ASC_DEMO_PASSWORD` value
   - `notes` = link to this runbook + sentinel UUIDs from §2
   Grant access to: belengaz, reso, founder mailbox.
2. **Codemagic** — Team → Global vars (NOT workflow-scoped):
   - `ASC_DEMO_USER` = reviewer email
   - `ASC_DEMO_PASSWORD` = password
   Mark both **secure** (encrypted at rest, masked in logs).
3. **App Store Connect** — no manual step. `fastlane deliver` reads them
   from env at upload time via `_demo_review_information` in
   `fastlane/Fastfile`.

### 3f. Final smoke test

```bash
cd fastlane && bundle exec fastlane ios deliver_dry_run
# Expected: "deliver dry-run passed — Ready to submit"
```

Save the full log to your secure drive (do **not** commit) and link it from
the issue close comment.

---

## 4. Rotation (every 90 days, or on staff change)

Rotation is **mandatory** if any of these happen:
- A staff member with 1Password access leaves
- The Codemagic dashboard is suspected of compromise
- 90 days have elapsed since the last rotation
- Apple ever asks us to rotate (extremely rare)

```bash
# 1. Generate new password (§3a).
# 2. Re-run the provisioning script with the new password — its idempotent
#    PUT branch rotates the password on the existing auth.users row.
export ASC_DEMO_PASSWORD="${NEW_ASC_DEMO_PASSWORD}"
bash scripts/provision_appstore_reviewer.sh
# 3. Update 1Password entry "App Store reviewer".
# 4. Update Codemagic global vars ASC_DEMO_PASSWORD (NOT ASC_DEMO_USER).
# 5. Run healthcheck:
bash scripts/check_appstore_reviewer.sh
# 6. Re-run deliver_dry_run (§3f) to confirm the new password lands in ASC.
# 7. If a TestFlight review is currently in-flight: note in App Store
#    Connect → My Apps → DeelMarkt → App Review → Reviewer Notes that
#    credentials were rotated and provide the new ones via the secure
#    Apple Developer message. NEVER email Apple credentials.
```

Cycle time target: **< 30 minutes**, including dry-run.

---

## 5. Recovery (healthcheck failed, fixture damaged)

### 5a. Identify the failure mode

```bash
bash scripts/check_appstore_reviewer.sh
```

The output names which check failed.

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `is_appstore_reviewer()` missing | Migration not applied | Re-run `supabase db push` |
| `auth.users` rows missing | Auth user accidentally deleted (§Revoke ran by mistake, or `supabase db reset` on staging) | Re-run §3b then §3c |
| `user_profiles` rows missing OR kyc_level wrong | Down-migration ran by mistake, or trigger overrode kyc | Re-run `supabase db push` |
| Listing `escrow_eligible=false` | Likely cause: `quality_score < 50` after a manual edit, OR the Electronics category was flipped non-eligible | Set `quality_score = 78` via migration re-apply (idempotent), confirm `categories.escrow_eligible = true` for Electronics |
| Transaction status not `paid` | An EF (e.g. `release-escrow` cron) advanced the state | Re-apply seed migration — `ON CONFLICT DO UPDATE` resets status to `paid` |
| Message count `< 2` | Messages cascade-deleted or chat moderation purged them | Re-apply seed migration |

### 5b. Nuke-and-pave

When in doubt:

```bash
# 1. Apply the down-migration (removes seeded rows; keeps auth.users intact).
psql "${SUPABASE_DB_URL}" \
  -f supabase/migrations/_rollback/20260425135428_seed_appstore_reviewer_account_down.sql
# 2. Re-apply the up-migration.
psql "${SUPABASE_DB_URL}" \
  -f supabase/migrations/20260425135427_seed_appstore_reviewer_account.sql
# 3. Verify.
bash scripts/check_appstore_reviewer.sh
```

This is safe because the seed migration is fully idempotent and touches only
the six sentinel UUIDs in §2.

---

## 6. Revoke (off-boarding the demo account permanently)

Only do this when DeelMarkt has graduated past App Review (e.g. the marketplace
is sunset, or App Review no longer requires a demo account — neither is
foreseeable through 2027). Revocation breaks every future `fastlane deliver`
until §3 is re-run.

```bash
# 0. Required env (same set as §3b — re-export if you opened a fresh shell):
#    export SUPABASE_PROJECT_REF=<from project URL>
#    export SUPABASE_SERVICE_ROLE_KEY=<from 1Password 'Supabase service_role'>
#    export SUPABASE_DB_URL=<postgres connection string>
# 1. Apply the down-migration (removes ancillary data).
psql "${SUPABASE_DB_URL}" \
  -f supabase/migrations/_rollback/20260425135428_seed_appstore_reviewer_account_down.sql
# 2. Delete the auth.users rows via the Auth Admin REST API.
#    SUPABASE_API_BASE_URL override only needed for self-hosted / dedicated;
#    SaaS defaults to https://${SUPABASE_PROJECT_REF}.supabase.co.
for id in aa162162-0000-0000-0000-000000000001 \
          aa162162-0000-0000-0000-000000000002; do
  curl -sS -X DELETE \
    "${SUPABASE_API_BASE_URL:-https://${SUPABASE_PROJECT_REF}.supabase.co}/auth/v1/admin/users/${id}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
done
# 3. Remove ASC_DEMO_USER / ASC_DEMO_PASSWORD from Codemagic.
# 4. Archive the 1Password entry (do NOT delete — keeps the audit trail).
# 5. Update fastlane/metadata/review_information/notes.txt to remove the
#    "use the demo account credentials above" sentence.
# 6. Disable .github/workflows/appstore-reviewer-healthcheck.yml
#    (rename to .yml.disabled; do not delete — preserves cron history).
```

---

## 7. Compliance & audit

- **GDPR / data retention:** the demo account uses the founder's already-
  published business identity (`Mahmut Kaya`, `+31686433636`,
  `support@deelmarkt.com`). It is **not** a real customer; standard
  90-day retention rotation (§4) is the only obligation. No DPIA required.
- **Analytics isolation:** any new analytics view, recommendation model, or
  trust-score aggregate **MUST** filter via `WHERE NOT public.is_appstore_reviewer(user_id)`
  to keep reviewer activity out of product metrics. Reviewer code paths
  are documented at the call site so the filter is discoverable.
- **Audit log:** every credential rotation creates a 1Password version
  history entry. If a security incident requires forensic review, dump
  1Password history + the corresponding Codemagic dashboard audit log
  (Team → Activity).

---

## 8. Related resources

- Plan: [docs/PLAN-gh162-testflight-review-info.md](../PLAN-gh162-testflight-review-info.md)
- Seed migration: [supabase/migrations/20260425135427_seed_appstore_reviewer_account.sql](../../supabase/migrations/20260425135427_seed_appstore_reviewer_account.sql)
- Down migration: [supabase/migrations/_rollback/20260425135428_seed_appstore_reviewer_account_down.sql](../../supabase/migrations/_rollback/20260425135428_seed_appstore_reviewer_account_down.sql)
- Provisioning script: [scripts/provision_appstore_reviewer.sh](../../scripts/provision_appstore_reviewer.sh)
- Healthcheck script: [scripts/check_appstore_reviewer.sh](../../scripts/check_appstore_reviewer.sh)
- Healthcheck workflow: [.github/workflows/appstore-reviewer-healthcheck.yml](../../.github/workflows/appstore-reviewer-healthcheck.yml)
- Fastlane lane: [fastlane/Fastfile](../../fastlane/Fastfile) `deliver_dry_run`
- App privacy YAML: [fastlane/metadata/review_information/privacy_details.yaml](../../fastlane/metadata/review_information/privacy_details.yaml)
- ASO copy validator: [scripts/check_aso.dart](../../scripts/check_aso.dart) `_checkReviewInformation`
- Project rules: [CLAUDE.md §13](../../CLAUDE.md) (marketing-asset guardrail)
