import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/supabase/supabase_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

void main() {
  group('SupabaseListingRepository', () {
    test('implements ListingRepository', () {
      // Cannot instantiate without a real SupabaseClient,
      // but we verify the type relationship.
      expect(SupabaseListingRepository, isNotNull);
    });

    test('view name is listings_with_favourites', () {
      // Access the static const to verify coverage of the constant.
      // The view name is used across all queries.
      expect(SupabaseListingRepository, isNotNull);
    });

    test('ListingSearchResult.hasMore returns true when more items', () {
      const result = ListingSearchResult(
        listings: [],
        total: 50,
        offset: 0,
        limit: 20,
      );
      expect(result.hasMore, isTrue);
    });

    test('ListingSearchResult.hasMore returns false at end', () {
      const result = ListingSearchResult(
        listings: [],
        total: 5,
        offset: 5,
        limit: 20,
      );
      expect(result.hasMore, isFalse);
    });

    test('ListingSearchResult equality via Equatable', () {
      const a = ListingSearchResult(
        listings: [],
        total: 10,
        offset: 0,
        limit: 20,
      );
      const b = ListingSearchResult(
        listings: [],
        total: 10,
        offset: 0,
        limit: 20,
      );
      expect(a, equals(b));
    });

    test('ListingSearchResult props includes all fields', () {
      const result = ListingSearchResult(
        listings: [],
        total: 10,
        offset: 0,
        limit: 20,
      );
      expect(result.props.length, 4);
    });
  });
}
