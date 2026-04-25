-- ──────────────────────────────────────────────────────────────────────────
-- GH #162 — App Store reviewer demo account seed
--
-- Idempotent seed for the App Store reviewer demo account ancillary data:
--   * 1 seller user_profile (kyc_level=level2, iDIN-bypassed)
--   * 1 buyer  user_profile (kyc_level=level2, companion synthetic account)
--   * 1 active escrow-eligible listing in Electronics (owned by seller)
--   * 1 transaction in 'paid' status (buyer paid seller, escrow holding)
--   * 1 conversation between buyer and seller
--   * 2 messages so seller_response_time_minutes is populated
--   * 1 helper SQL function `is_appstore_reviewer(uuid)` so analytics +
--     trust EFs can opt-in to filtering reviewer rows out of aggregates
--
-- IMPORTANT — auth.users provisioning is OUT OF SCOPE for this migration.
-- Supabase migrations cannot reliably insert into auth.users (the password
-- hash + raw_user_meta + email_confirmed_at + tokens flow through the
-- supabase-auth GoTrue server, not raw SQL). The two reviewer auth rows
-- MUST be created via the supabase CLI (or the Supabase dashboard) BEFORE
-- this migration runs in production. See:
--   docs/runbooks/RUNBOOK-appstore-reviewer.md  §Provisioning
--
-- The migration is wrapped in a DO block that detects whether the auth.users
-- rows exist and **becomes a no-op with a NOTICE** when they do not. This
-- means:
--   * `supabase db reset` on a fresh local stack succeeds (no auth rows yet)
--   * `supabase db push` against staging/prod after the runbook ran
--     populates the ancillary rows
--   * Re-running the migration later (after the runbook re-creates a rotated
--     auth user) re-syncs the ancillary rows via INSERT...ON CONFLICT
--
-- Rollback: pair with the matching `_down.sql` (same timestamp + 1).
--
-- Closes: #162 (Tier 1 task T1 in docs/PLAN-gh162-testflight-review-info.md)
-- ──────────────────────────────────────────────────────────────────────────

-- 1. Helper: is_appstore_reviewer(uuid) — STABLE so it can sit inside RLS
--    predicates and analytics views without write amplification. The two
--    sentinel UUIDs below are the SOLE source of truth for "this row
--    belongs to the App Store reviewer flow".
--
--    Sentinel UUIDs are deliberately memorable ("162" prefix matches the
--    GitHub issue) and stable across environments — never change them
--    without updating the runbook + healthcheck script.
CREATE OR REPLACE FUNCTION public.is_appstore_reviewer(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT p_user_id IN (
    'aa162162-0000-0000-0000-000000000001'::uuid,  -- reviewer seller
    'aa162162-0000-0000-0000-000000000002'::uuid   -- reviewer buyer
  );
$$;

COMMENT ON FUNCTION public.is_appstore_reviewer IS
  'Returns TRUE if the given user_id is one of the two reserved App Store '
  'reviewer accounts. Use in analytics / trust EFs to exclude reviewer '
  'activity from aggregate metrics. See docs/runbooks/RUNBOOK-appstore-reviewer.md.';

-- 2. Idempotent seed body. Runs only when both auth.users rows exist.
DO $appstore_reviewer_seed$
DECLARE
  v_seller_id   CONSTANT UUID := 'aa162162-0000-0000-0000-000000000001';
  v_buyer_id    CONSTANT UUID := 'aa162162-0000-0000-0000-000000000002';
  v_listing_id  CONSTANT UUID := 'aa162162-0000-0000-0000-000000000010';
  v_txn_id      CONSTANT UUID := 'aa162162-0000-0000-0000-000000000020';
  v_convo_id    CONSTANT UUID := 'aa162162-0000-0000-0000-000000000030';
  v_msg1_id     CONSTANT UUID := 'aa162162-0000-0000-0000-000000000031';
  v_msg2_id     CONSTANT UUID := 'aa162162-0000-0000-0000-000000000032';
  v_category_id CONSTANT UUID := 'c1000000-0000-0000-0000-000000000001'; -- Electronics (L1)
  v_seller_present BOOLEAN;
  v_buyer_present  BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM auth.users WHERE id = v_seller_id) INTO v_seller_present;
  SELECT EXISTS (SELECT 1 FROM auth.users WHERE id = v_buyer_id)  INTO v_buyer_present;

  IF NOT (v_seller_present AND v_buyer_present) THEN
    RAISE NOTICE
      'GH #162 seed skipped — App Store reviewer auth.users rows not provisioned. '
      'Run `supabase auth admin create-user` per docs/runbooks/RUNBOOK-appstore-reviewer.md '
      'then re-apply this migration. Missing: seller=%, buyer=%.',
      NOT v_seller_present, NOT v_buyer_present;
    RETURN;
  END IF;

  -- ── 2a. Seller profile (App Store demo account, KYC level2) ─────────────
  INSERT INTO public.user_profiles (
    id, display_name, location, kyc_level, badges,
    average_rating, review_count, response_time_minutes
  )
  VALUES (
    v_seller_id,
    'DeelMarkt Demo (Reviewer)',
    'Amsterdam',
    'level2',
    ARRAY['verified_kyc', 'app_store_reviewer'],
    4.9,
    12,
    15
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name           = EXCLUDED.display_name,
    location               = EXCLUDED.location,
    kyc_level              = EXCLUDED.kyc_level,
    badges                 = EXCLUDED.badges,
    average_rating         = EXCLUDED.average_rating,
    review_count           = EXCLUDED.review_count,
    response_time_minutes  = EXCLUDED.response_time_minutes,
    updated_at             = now();

  -- ── 2b. Buyer profile (companion synthetic account, KYC level2) ─────────
  INSERT INTO public.user_profiles (
    id, display_name, location, kyc_level, badges,
    average_rating, review_count
  )
  VALUES (
    v_buyer_id,
    'DeelMarkt Demo Buyer',
    'Rotterdam',
    'level2',
    ARRAY['verified_kyc', 'app_store_reviewer'],
    5.0,
    3
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name   = EXCLUDED.display_name,
    location       = EXCLUDED.location,
    kyc_level      = EXCLUDED.kyc_level,
    badges         = EXCLUDED.badges,
    average_rating = EXCLUDED.average_rating,
    review_count   = EXCLUDED.review_count,
    updated_at     = now();

  -- ── 2c. Listing (active, escrow-eligible, in Electronics) ───────────────
  --    quality_score >= 50 + price >= €50 + KYC>=level1 + Electronics
  --    eligible → escrow_eligible trigger will set TRUE automatically.
  INSERT INTO public.listings (
    id, seller_id, title, description, price_cents, condition, category_id,
    image_urls, location, latitude, longitude, quality_score, is_sold, is_active
  )
  VALUES (
    v_listing_id,
    v_seller_id,
    'iPhone 14 Pro 256GB - Demo Listing',
    'This is a demonstration listing seeded for App Store review. '
    'It exercises the full DeelMarkt buyer journey: escrow-protected payment, '
    'in-app chat, shipping label generation, and trust signals (KYC verified, '
    'high quality score). Reviewers can browse, message, and observe the '
    'escrow flow without affecting real users.',
    79900, -- €799.00
    'good',
    v_category_id,
    ARRAY[
      'https://res.cloudinary.com/deelmarkt-demo/image/upload/v1/reviewer/iphone-14-pro-1.jpg',
      'https://res.cloudinary.com/deelmarkt-demo/image/upload/v1/reviewer/iphone-14-pro-2.jpg'
    ],
    'Amsterdam',
    52.3676,
    4.9041,
    78,  -- quality_score >= 50
    false,
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    seller_id     = EXCLUDED.seller_id,
    title         = EXCLUDED.title,
    description   = EXCLUDED.description,
    price_cents   = EXCLUDED.price_cents,
    condition     = EXCLUDED.condition,
    category_id   = EXCLUDED.category_id,
    image_urls    = EXCLUDED.image_urls,
    location      = EXCLUDED.location,
    latitude      = EXCLUDED.latitude,
    longitude     = EXCLUDED.longitude,
    quality_score = EXCLUDED.quality_score,
    is_sold       = EXCLUDED.is_sold,
    is_active     = EXCLUDED.is_active,
    updated_at    = now();

  -- ── 2d. Transaction (paid, escrow holding) ──────────────────────────────
  --    Status 'paid' so the reviewer sees an active escrow holding when
  --    they navigate to "My purchases" or "Escrow".
  INSERT INTO public.transactions (
    id, listing_id, buyer_id, seller_id, status,
    item_amount_cents, platform_fee_cents, shipping_cost_cents,
    currency, mollie_payment_id, paid_at, escrow_deadline
  )
  VALUES (
    v_txn_id,
    v_listing_id,
    v_buyer_id,
    v_seller_id,
    'paid',
    79900,
    2397,  -- 3% platform fee
    695,   -- PostNL shipping
    'EUR',
    'tr_appstore_reviewer_demo',
    now() - INTERVAL '2 hours',
    now() + INTERVAL '14 days'
  )
  ON CONFLICT (id) DO UPDATE SET
    listing_id          = EXCLUDED.listing_id,
    buyer_id            = EXCLUDED.buyer_id,
    seller_id           = EXCLUDED.seller_id,
    status              = EXCLUDED.status,
    item_amount_cents   = EXCLUDED.item_amount_cents,
    platform_fee_cents  = EXCLUDED.platform_fee_cents,
    shipping_cost_cents = EXCLUDED.shipping_cost_cents,
    currency            = EXCLUDED.currency,
    mollie_payment_id   = EXCLUDED.mollie_payment_id,
    paid_at             = EXCLUDED.paid_at,
    escrow_deadline     = EXCLUDED.escrow_deadline,
    updated_at          = now();

  -- ── 2e. Conversation (buyer ⇄ seller for the listing) ───────────────────
  --    The conversations BEFORE-INSERT trigger overrides last_message_at,
  --    so we INSERT first, then UPDATE last_message_at to a deterministic
  --    value tied to the seeded messages below.
  INSERT INTO public.conversations (id, listing_id, buyer_id)
  VALUES (v_convo_id, v_listing_id, v_buyer_id)
  ON CONFLICT (listing_id, buyer_id) DO UPDATE SET
    -- bump no real columns; ON CONFLICT branch needed only to make the
    -- seed idempotent across re-runs
    listing_id = EXCLUDED.listing_id;

  -- ── 2f. Messages (buyer initiates → seller responds within 15 min) ──────
  INSERT INTO public.messages (
    id, conversation_id, sender_id, text, type, is_read, created_at
  )
  VALUES (
    v_msg1_id,
    v_convo_id,
    v_buyer_id,
    'Hi! Is this iPhone still available? Could you confirm the battery health?',
    'text',
    true,
    now() - INTERVAL '1 hour'
  )
  ON CONFLICT (id) DO UPDATE SET
    text       = EXCLUDED.text,
    is_read    = EXCLUDED.is_read,
    created_at = EXCLUDED.created_at;

  INSERT INTO public.messages (
    id, conversation_id, sender_id, text, type, is_read, created_at
  )
  VALUES (
    v_msg2_id,
    v_convo_id,
    v_seller_id,
    'Hi! Yes, still available. Battery health is 92%. Original box and charger included.',
    'text',
    false,
    now() - INTERVAL '45 minutes'
  )
  ON CONFLICT (id) DO UPDATE SET
    text       = EXCLUDED.text,
    is_read    = EXCLUDED.is_read,
    created_at = EXCLUDED.created_at;

  -- Force last_message_at to match the latest seeded message timestamp,
  -- bypassing the BEFORE-INSERT trigger (we are doing an UPDATE, not an
  -- INSERT, so the conversations_enforce_timestamps trigger does not fire).
  UPDATE public.conversations
     SET last_message_at = now() - INTERVAL '45 minutes'
   WHERE id = v_convo_id;

  RAISE NOTICE 'GH #162 seed applied — App Store reviewer fixture is ready.';
END
$appstore_reviewer_seed$;
