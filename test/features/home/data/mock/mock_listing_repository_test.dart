import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

void main() {
  late MockListingRepository repo;

  setUp(() {
    repo = MockListingRepository();
  });

  group('MockListingRepository', () {
    test('getRecent returns listings', () async {
      final listings = await repo.getRecent();

      expect(listings, isNotEmpty);
      expect(listings.first, isA<ListingEntity>());
    });

    test('getRecent respects limit', () async {
      final listings = await repo.getRecent(limit: 2);

      expect(listings.length, lessThanOrEqualTo(2));
    });

    test('getNearby filters by radius', () async {
      final nearby = await repo.getNearby(
        latitude: 52.37,
        longitude: 4.89,
        radiusKm: 5,
      );

      for (final listing in nearby) {
        expect(listing.distanceKm, isNotNull);
        expect(listing.distanceKm!, lessThanOrEqualTo(5));
      }
    });

    test('getById returns listing for valid id', () async {
      final listing = await repo.getById('listing-001');

      expect(listing, isNotNull);
      expect(listing!.id, equals('listing-001'));
    });

    test('getById returns null for invalid id', () async {
      final listing = await repo.getById('nonexistent');

      expect(listing, isNull);
    });

    test('search filters by query', () async {
      final result = await repo.search(query: 'iPhone');

      expect(result.listings, isNotEmpty);
      expect(result.total, greaterThan(0));
      expect(result.listings.first.title.toLowerCase(), contains('iphone'));
    });

    test('search returns empty for no match', () async {
      final result = await repo.search(query: 'zzznonexistent');

      expect(result.listings, isEmpty);
      expect(result.total, equals(0));
    });

    test('search filters by category', () async {
      final result = await repo.search(query: '', categoryId: 'cat-sport');

      for (final listing in result.listings) {
        expect(listing.categoryId, equals('cat-sport'));
      }
    });

    test('search filters by price range', () async {
      final result = await repo.search(
        query: '',
        minPriceCents: 5000,
        maxPriceCents: 80000,
      );

      for (final listing in result.listings) {
        expect(listing.priceInCents, greaterThanOrEqualTo(5000));
        expect(listing.priceInCents, lessThanOrEqualTo(80000));
      }
    });

    test('search hasMore works correctly', () async {
      final result = await repo.search(query: '', limit: 1);

      if (result.total > 1) {
        expect(result.hasMore, isTrue);
      }
    });

    test('toggleFavourite adds to favourites', () async {
      final updated = await repo.toggleFavourite('listing-001');

      expect(updated.isFavourited, isTrue);
    });

    test('toggleFavourite removes from favourites', () async {
      await repo.toggleFavourite('listing-001');
      final updated = await repo.toggleFavourite('listing-001');

      expect(updated.isFavourited, isFalse);
    });

    test('getFavourites returns favourited listings', () async {
      await repo.toggleFavourite('listing-001');
      await repo.toggleFavourite('listing-002');

      final favourites = await repo.getFavourites();

      expect(favourites.length, equals(2));
      expect(
        favourites.map((l) => l.id),
        containsAll(['listing-001', 'listing-002']),
      );
    });

    test('getFavourites returns empty when none favourited', () async {
      final favourites = await repo.getFavourites();

      expect(favourites, isEmpty);
    });
  });
}
