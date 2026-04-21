-- ──────────────────────────────────────────────────────────────────────────
-- DeelMarkt — Local dev seed: test users
--
-- Sanitized fixture users across KYC levels. Do NOT use these in prod —
-- passwords and emails are deliberately obvious so nobody confuses them with
-- real accounts.
--
-- All UUIDs are fixed so Dart widget tests and manual-QA scripts can
-- reference them verbatim.
--
-- Password for every seed user: `Password123!`
--
-- Convention:
--   11111111-* → buyers
--   22222222-* → sellers
--   33333333-* → admins
--
-- See docs/LOCAL-STACK.md and docs/TEST-MATRIX.md.
-- pragma: allowlist secret
-- ──────────────────────────────────────────────────────────────────────────

-- Skip if users already exist (makes the seed idempotent across reruns).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = '11111111-1111-1111-1111-111111111111') THEN

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_sso_user
    ) VALUES
      -- Buyers
      ('00000000-0000-0000-0000-000000000000',
       '11111111-1111-1111-1111-111111111111',
       'authenticated', 'authenticated', 'buyer-l0@deelmarkt.test',
       crypt('Password123!', gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}', '{}', false),
      ('00000000-0000-0000-0000-000000000000',
       '11111111-1111-1111-1111-111111111112',
       'authenticated', 'authenticated', 'buyer-l2@deelmarkt.test',
       crypt('Password123!', gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}', '{}', false),
      -- Sellers
      ('00000000-0000-0000-0000-000000000000',
       '22222222-2222-2222-2222-222222222221',
       'authenticated', 'authenticated', 'seller-kyc0@deelmarkt.test',
       crypt('Password123!', gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}', '{}', false),
      ('00000000-0000-0000-0000-000000000000',
       '22222222-2222-2222-2222-222222222222',
       'authenticated', 'authenticated', 'seller-kyc2@deelmarkt.test',
       crypt('Password123!', gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}', '{}', false),
      -- Admin
      ('00000000-0000-0000-0000-000000000000',
       '33333333-3333-3333-3333-333333333333',
       'authenticated', 'authenticated', 'admin@deelmarkt.test',
       crypt('Password123!', gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}', '{}', false);
  END IF;
END $$;

-- Profiles — ON CONFLICT DO NOTHING so reruns are safe.
INSERT INTO user_profiles (id, display_name, kyc_level, avatar_url, location, average_rating, review_count) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Test Buyer (L0)',      'level0', NULL, 'Amsterdam', NULL, 0),
  ('11111111-1111-1111-1111-111111111112', 'Test Buyer (L2)',      'level2', NULL, 'Rotterdam', 4.5,  12),
  ('22222222-2222-2222-2222-222222222221', 'Test Seller (KYC0)',   'level0', NULL, 'Utrecht',   3.8,  4),
  ('22222222-2222-2222-2222-222222222222', 'Test Seller (KYC2)',   'level2', NULL, 'Den Haag',  4.9,  48),
  ('33333333-3333-3333-3333-333333333333', 'Test Admin',           'level2', NULL, 'Amsterdam', NULL, 0)
ON CONFLICT (id) DO NOTHING;
