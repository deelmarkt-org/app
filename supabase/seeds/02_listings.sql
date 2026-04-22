-- ──────────────────────────────────────────────────────────────────────────
-- DeelMarkt — Local dev seed: listings
--
-- Sample listings spanning categories, prices, conditions, and quality
-- scores. Covers the matrix needed to exercise search/filter, escrow
-- badging (GH-59), and the home screen's "recent listings" row.
--
-- Categories referenced are from the bootstrap seed in migration
-- 20260329161637_phase_a_user_profiles_listings_categories_b39_to_b44.sql
-- (Electronics c1...01, Fashion c1...02, Home & Garden c1...03, etc.).
--
-- UUID pattern:
--   a1111111-* → listings from seller KYC2 (escrow-eligible candidates)
--   a2222222-* → listings from seller KYC0 (never eligible — KYC gate)
--
-- image_urls are placeholder Cloudinary delivery paths against the shared
-- team cloud; if your CLOUDINARY_URL points at a different cloud the
-- images will 404 but the data rows will still exercise the UI.
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO listings (
  id, seller_id, title, description, price_cents, condition, category_id,
  image_urls, location, latitude, longitude, quality_score,
  is_sold, is_active
) VALUES
  -- KYC2 seller, eligible price & quality → escrow candidate
  ('a1111111-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222',
   'iPhone 13 Pro 128GB — excellent condition',
   'Barely used, always in a case with screen protector. Original box and charger included. Comes with 3 months of warranty left.',
   65000, 'like_new', 'c1000000-0000-0000-0000-000000000001',
   ARRAY['dev-seed/iphone-13-pro-1.jpg', 'dev-seed/iphone-13-pro-2.jpg'],
   'Amsterdam', 52.3676, 4.9041, 85, false, true),

  ('a1111111-0000-0000-0000-000000000002',
   '22222222-2222-2222-2222-222222222222',
   'IKEA Poäng armchair — birch veneer',
   'Classic IKEA Poäng in birch. Good condition, some minor scuffs on the armrests. Cushion is clean.',
   8500, 'good', 'c1000000-0000-0000-0000-000000000003',
   ARRAY['dev-seed/poang-1.jpg'],
   'Den Haag', 52.0705, 4.3007, 72, false, true),

  ('a1111111-0000-0000-0000-000000000003',
   '22222222-2222-2222-2222-222222222222',
   'Nike Air Max 90 — size 43, white',
   'Worn a few times, mostly indoor. No visible wear, original box included.',
   7500, 'like_new', 'c1000000-0000-0000-0000-000000000002',
   ARRAY['dev-seed/airmax-1.jpg', 'dev-seed/airmax-2.jpg', 'dev-seed/airmax-3.jpg'],
   'Rotterdam', 51.9244, 4.4777, 78, false, true),

  -- KYC0 seller → escrow never eligible (fail-closed)
  ('a2222222-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222221',
   'Vintage Nikon FM2 film camera',
   '1980s SLR in working condition. Light meter works. Comes with 50mm f/1.8 lens. Needs a new battery.',
   12500, 'good', 'c1000000-0000-0000-0000-000000000005',
   ARRAY['dev-seed/nikon-fm2-1.jpg'],
   'Utrecht', 52.0907, 5.1214, 65, false, true),

  -- Sold listing — for testing filter "exclude sold"
  ('a1111111-0000-0000-0000-000000000099',
   '22222222-2222-2222-2222-222222222222',
   'Brompton M3L folding bike — black',
   'Sold already — kept for UI state testing.',
   95000, 'like_new', 'c1000000-0000-0000-0000-000000000004',
   ARRAY['dev-seed/brompton-1.jpg'],
   'Amsterdam', 52.3676, 4.9041, 88, true, true),

  -- Low price — below escrow threshold (price_cents < 5000)
  ('a1111111-0000-0000-0000-000000000010',
   '22222222-2222-2222-2222-222222222222',
   'Set of 4 Dutch cookbooks',
   'Three Ottolenghi, one Jamie Oliver. All in good condition.',
   3500, 'good', 'c1000000-0000-0000-0000-000000000005',
   ARRAY['dev-seed/cookbooks-1.jpg'],
   'Amsterdam', 52.3676, 4.9041, 55, false, true)

ON CONFLICT (id) DO NOTHING;
