-- ──────────────────────────────────────────────────────────────────────────
-- GH-59 / ADR-023 — Expose `listings.escrow_eligible` through the
-- `listings_with_favourites` view.
--
-- Context (PR #185 review, mahmutkaya):
--   Migration 20260420154314_listings_escrow_eligible.sql adds the column
--   `listings.escrow_eligible`. The Dart data layer
--   (supabase_listing_repository.dart, listing_dto.dart) reads the column
--   from the `listings_with_favourites` view, NOT the base table. That view
--   was last recreated on 2026-04-03 (20260403100000_r20_account_deletion_
--   support.sql) with `SELECT l.* FROM listings l`.
--
--   PostgreSQL expands `l.*` to the concrete column list at CREATE VIEW
--   time — columns added to the underlying table afterwards are NOT
--   retroactively exposed through the view. Without this migration:
--     • `SELECT escrow_eligible FROM listings_with_favourites` → error
--     • The DTO's fail-closed parse returns `false` for every row
--     • The EscrowAwareListingCard flag-gated render is never taken
--     • The entire GH-59 feature ships silently non-functional in prod
--       behind 100% unit coverage and a green SonarCloud gate.
--
--   This migration re-runs the same DROP + CREATE pattern from
--   20260403100000 so `l.*` is re-expanded with the current column set,
--   picking up `escrow_eligible` (plus any future columns added to
--   `listings` before this migration is applied).
--
-- Rollback: paired `_down.sql` drops the view. Manual re-apply of
--   20260403100000_r20 (or this migration) rebuilds it. See the down file
--   for the ordered rollback sequence alongside
--   20260420154315_listings_escrow_eligible_down.sql.
-- ──────────────────────────────────────────────────────────────────────────

-- Drop first because the view's column set is changing (new trailing
-- `escrow_eligible` column). `CREATE OR REPLACE VIEW` cannot add columns
-- without also reordering, and the safer explicit DROP matches the 2026-04-03
-- convention for this view.
DROP VIEW IF EXISTS listings_with_favourites;

CREATE VIEW listings_with_favourites AS
SELECT
  l.*,
  up.display_name AS seller_name,
  up.avatar_url AS seller_avatar_url,
  up.average_rating AS seller_rating,
  up.kyc_level AS seller_kyc_level,
  CASE
    WHEN (SELECT auth.uid()) IS NULL THEN false
    ELSE EXISTS(
      SELECT 1 FROM favourites f
      WHERE f.listing_id = l.id AND f.user_id = (SELECT auth.uid())
    )
  END AS is_favourited
FROM listings l
LEFT JOIN user_profiles up ON up.id = l.seller_id
WHERE l.deleted_at IS NULL;

GRANT SELECT ON listings_with_favourites TO authenticated, anon;

COMMENT ON VIEW listings_with_favourites IS
  'Listings joined with seller profile + per-user favourite flag. '
  'Re-created on 2026-04-20 to pick up listings.escrow_eligible via l.*. '
  'Re-running this DROP+CREATE after any listings column addition is the '
  'canonical fix — ALTER TABLE ADD COLUMN does not propagate through the '
  'view''s column list (PostgreSQL expands * at CREATE time).';
