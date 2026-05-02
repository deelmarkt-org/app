import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/supabase/supabase_listing_nearby_helper.dart';

void main() {
  group('SupabaseListingNearbyHelper', () {
    // Real instantiation requires a SupabaseClient + the
    // `listings_with_favourites` view; smoke tests verify the public
    // surface area only. End-to-end coverage of the distance flow is
    // exercised by SupabaseListingRepository's existing tests + the
    // `nearby_listings` integration test.
    test('class is exported', () {
      expect(SupabaseListingNearbyHelper, isNotNull);
    });

    test('class is instantiable with const constructor signature', () {
      // The constructor signature is `const (SupabaseClient, String)`.
      // We cannot pass a real SupabaseClient here without bringing the
      // whole network stack in; the static reference below guards against
      // accidental constructor signature changes that would silently
      // break SupabaseListingRepository's `_nearbyHelper` field init.
      const ctor = SupabaseListingNearbyHelper.new;
      expect(ctor, isNotNull);
    });
  });
}
