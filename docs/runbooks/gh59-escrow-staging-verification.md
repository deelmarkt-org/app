# GH-59 / ADR-023 — Escrow Eligibility Staging Verification

> **Purpose:** deterministic, reproducible verification of the three merge-gating
> items on PR [#184](https://github.com/deelmarkt-org/app/pull/184). Run this
> runbook against the **staging** Supabase + Unleash environment before removing
> the draft flag.
>
> **Owner:** reso (backend). Estimated wall-clock: **~15 minutes**.
>
> **References:**
> - Migration: [`supabase/migrations/20260420154314_listings_escrow_eligible.sql`](../../supabase/migrations/20260420154314_listings_escrow_eligible.sql)
> - ADR: [`docs/adr/ADR-023-escrow-eligibility-authority.md`](../adr/ADR-023-escrow-eligibility-authority.md)
> - Flag registry: [`docs/FEATURE-FLAGS.md`](../FEATURE-FLAGS.md)

## Prerequisites

- [ ] `psql` connected to the **staging** Supabase DB using the `service_role`
  role. Anon role cannot UPDATE `user_profiles.kyc_level`.
- [ ] Staging build of the Flutter app pointed at staging Supabase.
- [ ] Unleash admin console access for the staging instance.
- [ ] Two terminal windows: one for `psql`, one for `stopwatch` timing.

## Gate 1 — Badge appears on eligible listing after migration seed

**What this proves:** the `BEFORE INSERT` trigger writes `escrow_eligible = true`
when all six inputs are satisfied, and the client renders the badge end-to-end.

```sql
-- 1.1 Pick a seller with kyc_level >= level1.
SELECT id, kyc_level
  FROM user_profiles
 WHERE kyc_level <> 'level0'
 LIMIT 1;
-- → save as :seller_id

-- 1.2 Pick an escrow-eligible category.
SELECT id
  FROM categories
 WHERE escrow_eligible = true
 LIMIT 1;
-- → save as :category_id

-- 1.3 Insert a listing that satisfies every gate.
INSERT INTO listings (
  seller_id, category_id,
  title, description,
  price_cents, quality_score,
  is_active, is_sold
) VALUES (
  :'seller_id', :'category_id',
  'QA: escrow eligible (delete me)', 'runbook seed',
  6000, 75,
  true, false
)
RETURNING id, escrow_eligible;
-- Expected: escrow_eligible = true  (set by trg_listings_escrow_eligible BEFORE INSERT)
```

**Pass criteria:**

- [ ] `RETURNING escrow_eligible` is `true`.
- [ ] Staging app home grid shows the `DeelBadge(type: escrowProtected)` on
  the seeded card within one pull-to-refresh.
- [ ] Turning the Unleash flag `listings_escrow_badge` OFF and refreshing
  removes the badge (proves the flag gate is live in staging too).

**Teardown:**

```sql
DELETE FROM listings WHERE id = :'listing_id';
```

## Gate 2 — Badge disappears <1s after seller KYC downgrade

**What this proves:** `trg_user_profiles_kyc_cascade` fires on the seller's
`kyc_level` change, recomputes every row scoped by `seller_id`, and the UI
observes the flip within the 1-second SLA promised to legal.

```sql
-- 2.1 Seed a second eligible listing (or reuse 1.3 if still present).
--     Capture the current kyc_level so teardown can restore it.
SELECT kyc_level FROM user_profiles WHERE id = :'seller_id';
-- → save as :original_kyc

-- 2.2 Start a timer.
\timing on

-- 2.3 Trigger the cascade.
UPDATE user_profiles
   SET kyc_level = 'level0'
 WHERE id = :'seller_id';
-- Expected: single UPDATE statement, duration reported by \timing.

-- 2.4 Verify all seller listings flipped to false.
SELECT id, escrow_eligible
  FROM listings
 WHERE seller_id = :'seller_id';
-- Expected: every row escrow_eligible = false.

\timing off
```

**Pass criteria:**

- [ ] Cascade UPDATE completes in **<500ms** on a seller with <100 listings.
  (SLA target is <1s total, leaving budget for Realtime push + UI rebuild.)
- [ ] Staging app badge disappears within **1s** of the UPDATE commit —
  confirmed either by Realtime subscription or a single pull-to-refresh.
- [ ] `listings_with_favourites.escrow_eligible` column returns `false` for
  every row of this seller (view inherits from `l.*`).

**Teardown:**

```sql
UPDATE user_profiles SET kyc_level = :'original_kyc' WHERE id = :'seller_id';
-- Cascade re-fires, flipping eligibility back where all other gates pass.
```

## Gate 3 — Flag OFF in prod → zero badge renders

**What this proves:** even when the DB reports `escrow_eligible = true`, the
client-side flag gate in `EscrowAwareListingCard.build()` suppresses the badge.
This is the defence-in-depth layer that lets ops flip the kill switch in seconds.

**Steps (no SQL — this validates the Dart gate against prod Unleash):**

1. Unleash admin console → environment **`prod`** → toggle `listings_escrow_badge`.
   Confirm default state is **OFF** and matches [`docs/FEATURE-FLAGS.md`](../FEATURE-FLAGS.md).
2. Install a **prod** build on a device (or run from a prod-pointed TestFlight
   lane). Do NOT use the staging build for this gate.
3. Navigate to any listing known from logs to have `escrow_eligible = true`.

**Pass criteria:**

- [ ] Zero `DeelBadge(type: escrowProtected)` renders anywhere in the prod app.
- [ ] Unleash `listings_escrow_badge` environment panel still shows `prod = OFF`
  after the test (no accidental flip).

> ⚠️ Do not flip the flag to ON in prod during this test. Production rollout is
> a separate belengaz-owned operation documented in `docs/FEATURE-FLAGS.md`
> §Canary diagnostics and gated by legal sign-off.

## Sign-off

Once all three gates pass:

1. Tick the merge-gating checkboxes in PR [#184](https://github.com/deelmarkt-org/app/pull/184).
2. Remove the DRAFT flag: `gh pr ready 184`.
3. `deelmarkt-dev` already approved post-rebase — the merge button will enable.
4. After merge, belengaz starts the staged Unleash rollout per
   `docs/FEATURE-FLAGS.md` §Canary diagnostics.

## Rollback

The migration is additive — no destructive rollback is required.

- **Flag-level kill switch** (seconds): Unleash console → flip
  `listings_escrow_badge` to OFF. Server keeps computing `escrow_eligible`;
  the client simply stops reading it.
- **Column-level rollback** (if a correctness issue in the trigger surfaces):
  apply the paired down migration [`20260420154315_listings_escrow_eligible_down.sql`](../../supabase/migrations/20260420154315_listings_escrow_eligible_down.sql).
  Drops happen in reverse-dependency order (cascade triggers → primary trigger
  → function → index → columns). Zero data loss — the column value is reproducible
  from the other gates any time the migration is re-applied.
