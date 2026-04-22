-- ──────────────────────────────────────────────────────────────────────────
-- Hardening: lock search_path on all public schema functions
--
-- Supabase Security Advisor flags 13 functions in `public` without an
-- explicit `SET search_path`. A mutable search_path is exploitable when
-- a function is called by a role that can INSERT into a schema earlier
-- in `search_path` — the caller can shadow a built-in (e.g. place a
-- malicious `public.now()`) and have the function execute it.
--
-- The fix is one line per function: `SET search_path = public,
-- pg_catalog`. Includes `pg_catalog` explicitly so built-ins resolve
-- safely even if `public` is shadowed.
--
-- Applied via `ALTER FUNCTION` (no-op on body) to avoid re-writing the
-- 13 definitions. If any of these functions are recreated later with
-- `CREATE OR REPLACE FUNCTION` without the SET clause, the Security
-- Advisor will flag it again — add `SET search_path = public,
-- pg_catalog` inside every new function definition.
--
-- Surfaced by the local-stack audit during the PR #186 bootstrap work.
-- ──────────────────────────────────────────────────────────────────────────

ALTER FUNCTION public.calculate_platform_fee()                                  SET search_path = public, pg_catalog;
ALTER FUNCTION public.check_listing_images()                                    SET search_path = public, pg_catalog;
ALTER FUNCTION public.check_seller_profile_exists()                             SET search_path = public, pg_catalog;
ALTER FUNCTION public.conversations_set_timestamps()                            SET search_path = public, pg_catalog;
ALTER FUNCTION public.haversine_km(double precision, double precision,
                                   double precision, double precision)         SET search_path = public, pg_catalog;
ALTER FUNCTION public.nearby_listings(double precision, double precision,
                                      double precision, integer)                SET search_path = public, pg_catalog;
ALTER FUNCTION public.on_tracking_delivered()                                   SET search_path = public, pg_catalog;
ALTER FUNCTION public.set_escrow_deadline()                                     SET search_path = public, pg_catalog;
ALTER FUNCTION public.update_category_listing_count()                           SET search_path = public, pg_catalog;
ALTER FUNCTION public.update_conversation_last_message_at()                     SET search_path = public, pg_catalog;
ALTER FUNCTION public.update_favourite_count()                                  SET search_path = public, pg_catalog;
ALTER FUNCTION public.update_updated_at()                                       SET search_path = public, pg_catalog;
ALTER FUNCTION public.validate_transaction_status_transition()                  SET search_path = public, pg_catalog;
