-- ──────────────────────────────────────────────────────────────────────────
-- DeelMarkt — Local dev seed: favourites
--
-- A few cross-user favourites so the "Favorites" tab and listing card
-- heart-state have real data to render.
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO favourites (user_id, listing_id) VALUES
  ('11111111-1111-1111-1111-111111111111', 'a1111111-0000-0000-0000-000000000001'), -- buyer L0 ❤ iPhone
  ('11111111-1111-1111-1111-111111111111', 'a1111111-0000-0000-0000-000000000003'), -- buyer L0 ❤ Air Max
  ('11111111-1111-1111-1111-111111111112', 'a1111111-0000-0000-0000-000000000002'), -- buyer L2 ❤ Poäng
  ('11111111-1111-1111-1111-111111111112', 'a2222222-0000-0000-0000-000000000001')  -- buyer L2 ❤ Nikon
ON CONFLICT (user_id, listing_id) DO NOTHING;

-- Sync favourite_count on the listings rows so the UI doesn't show zero.
UPDATE listings SET favourite_count = sub.ct
FROM (
  SELECT listing_id, COUNT(*)::int AS ct
  FROM favourites GROUP BY listing_id
) sub
WHERE listings.id = sub.listing_id;
