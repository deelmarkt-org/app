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
    createdAt: DateTime(2026, 1, 1),
    location: 'Amsterdam',
    distanceKm: 5.0,
  );

  group('ListingEntity', () {
    test('equality by id', () {
      final same = ListingEntity(
        id: 'test-1',
        title: 'Different Title',
        description: 'Different',
        priceInCents: 9999,
        sellerId: 'user-2',
        sellerName: 'Other',
        condition: ListingCondition.fair,
        categoryId: 'cat-2',
        imageUrls: const [],
        createdAt: DateTime(2026, 3, 1),
      );

      expect(listing, equals(same));
      expect(listing.hashCode, equals(same.hashCode));
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
        createdAt: DateTime(2026, 1, 1),
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
}
