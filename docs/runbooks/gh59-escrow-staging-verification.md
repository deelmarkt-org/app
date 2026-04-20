# GH-59 / ADR-023 — Escrow Eligibility Staging Verification

> **Purpose:** deterministic, reproducible verification of the three merge-gating
> items on PR [#184](https://github.com/deelmarkt-org/app/pull/184). Run this
> runbook against the **staging** Supabase + Unleash environment before removing
> the draft flag.
>
> **Owner:** reso (backend). Estimated wall-clock: **~15 minutes**.
>
> **References:**
> - Migration (column + triggers): [`supabase/migrations/20260420154314_listings_escrow_eligible.sql`](../../supabase/migrations/20260420154314_listings_escrow_eligible.sql)
> - Migration (view passthrough): [`supabase/migrations/20260420160000_listings_with_favourites_expose_escrow_eligible.sql`](../../supabase/migrations/20260420160000_listings_with_favourites_expose_escrow_eligible.sql)
> - ADR: [`docs/adr/ADR-023-escrow-eligibility-authority.md`](../adr/ADR-023-escrow-eligibility-authority.md)
> - Flag registry: [`docs/FEATURE-FLAGS.md`](../FEATURE-FLAGS.md)

## Prerequisites

- [ ] `psql` connected to the **staging** Supabase DB using the `service_role`
  role. Anon role cannot UPDATE `user_profiles.kyc_level`.
- [ ] Staging build of the Flutter app pointed at staging Supabase.
- [ ] Unleash admin console access for the staging instance.
- [ ] Two terminal windows: one for `psql`, one for `stopwatch` timing.

## Gate 0 — `listings_with_favourites` view exposes `escrow_eligible`

**What this proves:** the view's column list actually includes the new
`escrow_eligible` column. The Dart data layer
([`lib/features/home/data/supabase/supabase_listing_repository.dart`](../../lib/features/home/data/supabase/supabase_listing_repository.dart))
queries this view, not the base table. If the column is absent the DTO's
fail-closed parse silently returns `false` for every row and the badge
never renders — behind green CI.

> **Why this gate exists.** PostgreSQL expands `SELECT l.*` inside a view to
> the concrete column list **at CREATE VIEW time**. Migration
> `20260420154314` adds `listings.escrow_eligible` but cannot retroactively
> alter the view created on 2026-04-03. Migration
> `20260420160000_listings_with_favourites_expose_escrow_eligible.sql`
> re-snapshots the view; this gate asserts it was actually applied.

```sql
-- 0.1 Assert the view exposes the escrow_eligible column.
SELECT column_name
  FROM information_schema.columns
 WHERE table_schema = 'public'
   AND table_name   = 'listings_with_favourites'
   AND column_name  = 'escrow_eligible';
-- Expected: exactly one row returned.

-- 0.2 Defence-in-depth: confirm the view actually returns the value
--     for a real row (not merely that the column exists).
SELECT id, escrow_eligible
  FROM listings_with_favourites
 LIMIT 1;
-- Expected: a row with escrow_eligible = true OR false (never NULL for
-- new rows; only pre-backfill rows could theoretically be NULL, and the
-- backfill in 20260420154314 covered them).
```

**Pass criteria:**

- [ ] Query 0.1 returns exactly one row.
- [ ] Query 0.2 returns a value (true or false) — if it errors with
  `column "escrow_eligible" does not exist`, the view migration did not
  apply; stop and re-run `bash scripts/check_deployments.sh --deploy`.

If Gate 0 fails, Gates 1-3 cannot pass. Fix before proceeding.

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
-- → save the returned id as :listing_id (used by the teardown step below).
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

1. Unleash admin console → environment **`prod`** → **inspect** (do NOT flip)
   the toggle `listings_escrow_badge`. Confirm current state is **OFF** and
   matches [`docs/FEATURE-FLAGS.md`](../FEATURE-FLAGS.md).
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
- **Column-level rollback** (if a correctness issue in the trigger surfaces),
  ordered as:
  1. Apply [`20260420160001_listings_with_favourites_expose_escrow_eligible_down.sql`](../../supabase/migrations/20260420160001_listings_with_favourites_expose_escrow_eligible_down.sql)
     first — drops the view so the column drop below is not blocked by
     dependency.
  2. Apply [`20260420154315_listings_escrow_eligible_down.sql`](../../supabase/migrations/20260420154315_listings_escrow_eligible_down.sql) —
     reverse-dependency drops (cascade triggers → primary trigger → function
     → index → columns).
  3. Rebuild the view: re-apply `20260420160000_listings_with_favourites_expose_escrow_eligible.sql`
     (now without `escrow_eligible` in `l.*` because step 2 removed the
     column). Until step 3 completes, the listings query layer returns no
     rows — this is intentional and paged, not silent.

  Zero data loss — the column value is reproducible from the other gates
  any time the up migrations are re-applied.
