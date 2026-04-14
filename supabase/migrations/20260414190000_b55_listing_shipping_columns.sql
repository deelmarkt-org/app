-- B-55 review fix H2: Add shipping_carrier and weight_range columns to listings.
--
-- These fields are accepted by the ListingCreationRepository interface
-- but had no DB backing. Without them, seller shipping configuration
-- was silently dropped on every create/saveDraft call.
--
-- Reference: PR #154 review comment H2

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS shipping_carrier TEXT NOT NULL DEFAULT 'none'
    CHECK (shipping_carrier IN ('postnl', 'dhl', 'none')),
  ADD COLUMN IF NOT EXISTS weight_range TEXT
    CHECK (weight_range IS NULL OR weight_range IN (
      'zero_to_two', 'two_to_five', 'five_to_ten',
      'ten_to_twenty_three', 'twenty_three_to_thirty_one'
    ));
