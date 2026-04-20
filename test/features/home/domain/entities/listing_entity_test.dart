import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

void main() {
  final listing = ListingEntity(
    id: 'test-1',
    title: 'Test Listing',
    description: 'A test listing',
    priceInCents: 5000,
    sellerId: 'user-1',
    sellerName: 'Test User',
    condition: ListingCondition.good,
    categoryId: 'cat-1',
    imageUrls: const ['https://example.com/img.jpg'],
    createdAt: DateTime(2026),
    location: 'Amsterdam',
    distanceKm: 5.0,
  );

  group('ListingEntity', () {
    test('equality when all fields match', () {
      final same = ListingEntity(
        id: 'test-1',
        title: 'Test Listing',
        description: 'A test listing',
        priceInCents: 5000,
        sellerId: 'user-1',
        sellerName: 'Test User',
        condition: ListingCondition.good,
        categoryId: 'cat-1',
        imageUrls: const ['https://example.com/img.jpg'],
        createdAt: DateTime(2026),
        location: 'Amsterdam',
        distanceKm: 5.0,
      );

      expect(listing, equals(same));
      expect(listing.hashCode, equals(same.hashCode));
    });

    test('inequality when fields differ (Riverpod state diffing)', () {
      final differentTitle = ListingEntity(
        id: 'test-1',
        title: 'Different Title',
        description: 'A test listing',
        priceInCents: 5000,
        sellerId: 'user-1',
        sellerName: 'Test User',
        condition: ListingCondition.good,
        categoryId: 'cat-1',
        imageUrls: const ['https://example.com/img.jpg'],
        createdAt: DateTime(2026),
        location: 'Amsterdam',
        distanceKm: 5.0,
      );

      expect(listing, isNot(equals(differentTitle)));
    });

    test('inequality by different id', () {
      final different = ListingEntity(
        id: 'test-2',
        title: 'Test Listing',
        description: 'A test listing',
        priceInCents: 5000,
        sellerId: 'user-1',
        sellerName: 'Test User',
        condition: ListingCondition.good,
        categoryId: 'cat-1',
        imageUrls: const [],
        createdAt: DateTime(2026),
      );

      expect(listing, isNot(equals(different)));
    });

    test('copyWith updates isFavourited', () {
      final updated = listing.copyWith(isFavourited: true);

      expect(updated.isFavourited, isTrue);
      expect(updated.id, equals(listing.id));
      expect(updated.title, equals(listing.title));
      expect(updated.priceInCents, equals(listing.priceInCents));
    });

    test('copyWith updates qualityScore', () {
      final updated = listing.copyWith(qualityScore: 85);

      expect(updated.qualityScore, equals(85));
      expect(updated.isFavourited, equals(listing.isFavourited));
    });

    test('default isFavourited is false', () {
      expect(listing.isFavourited, isFalse);
    });

    test('qualityScore is nullable', () {
      expect(listing.qualityScore, isNull);
    });
  });

  group('ListingEntity copyWith — all fields', () {
    test('returns identical entity when no fields overridden', () {
      expect(listing.copyWith(), equals(listing));
    });

    test('overrides title', () {
      final updated = listing.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.id, listing.id);
    });

    test('overrides priceInCents', () {
      final updated = listing.copyWith(priceInCents: 9999);
      expect(updated.priceInCents, 9999);
    });

    test('overrides condition', () {
      final updated = listing.copyWith(condition: ListingCondition.poor);
      expect(updated.condition, ListingCondition.poor);
    });

    test('overrides imageUrls', () {
      final updated = listing.copyWith(imageUrls: ['a.jpg', 'b.jpg']);
      expect(updated.imageUrls, ['a.jpg', 'b.jpg']);
    });

    test('overrides location and distanceKm', () {
      final updated = listing.copyWith(location: 'Rotterdam', distanceKm: 12.5);
      expect(updated.location, 'Rotterdam');
      expect(updated.distanceKm, 12.5);
    });

    test('overrides multiple fields at once', () {
      final updated = listing.copyWith(
        title: 'Updated',
        priceInCents: 100,
        sellerId: 'user-2',
        sellerName: 'Other User',
        categoryId: 'cat-2',
        createdAt: DateTime(2026, 6),
      );
      expect(updated.title, 'Updated');
      expect(updated.priceInCents, 100);
      expect(updated.sellerId, 'user-2');
      expect(updated.sellerName, 'Other User');
      expect(updated.categoryId, 'cat-2');
      expect(updated.createdAt, DateTime(2026, 6));
    });

    test('overrides description', () {
      final updated = listing.copyWith(description: 'New description');
      expect(updated.description, 'New description');
    });
  });

  group('ListingCondition', () {
    test('has 6 values', () {
      expect(ListingCondition.values.length, equals(6));
    });

    test('values are correct', () {
      expect(ListingCondition.values, contains(ListingCondition.newWithTags));
      expect(ListingCondition.values, contains(ListingCondition.likeNew));
      expect(ListingCondition.values, contains(ListingCondition.poor));
    });
  });

  group('ListingEntity.isEscrowAvailable', () {
    test('defaults to false (fail-closed, ADR-023)', () {
      expect(listing.isEscrowAvailable, isFalse);
    });

    test('can be set via the constructor', () {
      final eligible = ListingEntity(
        id: 'test-2',
        title: 'Eligible',
        description: 'desc',
        priceInCents: 10000,
        sellerId: 'user-1',
        sellerName: 'Test',
        condition: ListingCondition.good,
        categoryId: 'cat-1',
        imageUrls: const [],
        createdAt: DateTime(2026),
        isEscrowAvailable: true,
      );
      expect(eligible.isEscrowAvailable, isTrue);
    });

    test('copyWith toggles the value while preserving others', () {
      final flipped = listing.copyWith(isEscrowAvailable: true);
      expect(flipped.isEscrowAvailable, isTrue);
      expect(flipped.id, equals(listing.id));
      expect(flipped.priceInCents, equals(listing.priceInCents));
    });

    test('copyWith without isEscrowAvailable keeps the current value', () {
      final eligible = listing.copyWith(isEscrowAvailable: true);
      final reTitled = eligible.copyWith(title: 'New title');
      expect(reTitled.isEscrowAvailable, isTrue);
    });

    test('equality distinguishes entities that differ only by escrow flag', () {
      final eligible = listing.copyWith(isEscrowAvailable: true);
      expect(eligible, isNot(equals(listing)));
      expect(eligible.hashCode, isNot(equals(listing.hashCode)));
    });
  });
}
