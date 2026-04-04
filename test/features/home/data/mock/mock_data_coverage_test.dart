import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_data.dart';
import 'package:deelmarkt/features/home/data/mock/mock_l2_category_data.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_data.dart';

void main() {
  group('mock_category_data', () {
    test('l1Categories has 8 entries', () {
      expect(l1Categories, hasLength(8));
    });

    test('all L1 categories have unique IDs', () {
      final ids = l1Categories.map((c) => c.id).toSet();
      expect(ids, hasLength(l1Categories.length));
    });

    test('all L1 categories are top-level (no parentId)', () {
      for (final cat in l1Categories) {
        expect(cat.parentId, isNull, reason: '${cat.id} should be top-level');
      }
    });

    test('category ID constants match actual category IDs', () {
      expect(catVehicles, 'cat-vehicles');
      expect(catElectronics, 'cat-electronics');
      expect(catHome, 'cat-home');
      expect(catClothing, 'cat-clothing');
      expect(catSport, 'cat-sport');
      expect(catKids, 'cat-kids');
      expect(catServices, 'cat-services');
      expect(catOther, 'cat-other');
    });

    test('all L1 categories have non-empty names and icons', () {
      for (final cat in l1Categories) {
        expect(cat.name, isNotEmpty, reason: '${cat.id} name');
        expect(cat.icon, isNotEmpty, reason: '${cat.id} icon');
      }
    });

    test('all L1 categories have listing counts', () {
      for (final cat in l1Categories) {
        expect(
          cat.listingCount,
          greaterThan(0),
          reason: '${cat.id} listingCount',
        );
      }
    });
  });

  group('mock_l2_category_data', () {
    test('l2Categories is not empty', () {
      expect(l2Categories, isNotEmpty);
    });

    test('all L2 categories have unique IDs', () {
      final ids = l2Categories.map((c) => c.id).toSet();
      expect(ids, hasLength(l2Categories.length));
    });

    test('all L2 categories have a parentId', () {
      for (final cat in l2Categories) {
        expect(
          cat.parentId,
          isNotNull,
          reason: '${cat.id} should have parentId',
        );
      }
    });

    test('all L2 parentIds reference valid L1 categories', () {
      final l1Ids = l1Categories.map((c) => c.id).toSet();
      for (final cat in l2Categories) {
        expect(
          l1Ids,
          contains(cat.parentId),
          reason: '${cat.id} parentId ${cat.parentId} not in L1',
        );
      }
    });

    test('every L1 category has at least one L2 subcategory', () {
      final l1Ids = l1Categories.map((c) => c.id).toSet();
      final parentsWithChildren = l2Categories.map((c) => c.parentId).toSet();
      for (final l1Id in l1Ids) {
        expect(
          parentsWithChildren,
          contains(l1Id),
          reason: '$l1Id has no subcategories',
        );
      }
    });

    test('all L2 categories have non-empty names and icons', () {
      for (final cat in l2Categories) {
        expect(cat.name, isNotEmpty, reason: '${cat.id} name');
        expect(cat.icon, isNotEmpty, reason: '${cat.id} icon');
      }
    });
  });

  group('mock_listing_data', () {
    test('mockListings is not empty', () {
      expect(mockListings, isNotEmpty);
    });

    test('all listings have unique IDs', () {
      final ids = mockListings.map((l) => l.id).toSet();
      expect(ids, hasLength(mockListings.length));
    });

    test('all listings have required fields populated', () {
      for (final listing in mockListings) {
        expect(listing.title, isNotEmpty, reason: '${listing.id} title');
        expect(
          listing.description,
          isNotEmpty,
          reason: '${listing.id} description',
        );
        expect(
          listing.priceInCents,
          greaterThan(0),
          reason: '${listing.id} price',
        );
        expect(listing.sellerId, isNotEmpty, reason: '${listing.id} sellerId');
        expect(
          listing.sellerName,
          isNotEmpty,
          reason: '${listing.id} sellerName',
        );
        expect(
          listing.categoryId,
          isNotEmpty,
          reason: '${listing.id} categoryId',
        );
        expect(
          listing.imageUrls,
          isNotEmpty,
          reason: '${listing.id} imageUrls',
        );
        expect(listing.location, isNotEmpty, reason: '${listing.id} location');
      }
    });

    test('sampleImageUrl is a valid URL', () {
      expect(sampleImageUrl, startsWith('https://'));
    });

    test('listings span multiple categories', () {
      final categories = mockListings.map((l) => l.categoryId).toSet();
      expect(categories.length, greaterThan(1));
    });

    test('listings have various conditions', () {
      final conditions = mockListings.map((l) => l.condition).toSet();
      expect(conditions.length, greaterThan(1));
    });

    test('some listings have distance populated', () {
      final withDistance =
          mockListings.where((l) => l.distanceKm != null).toList();
      expect(withDistance, isNotEmpty);
    });

    test('at least one listing has sold status', () {
      final sold = mockListings.where((l) => l.status == ListingStatus.sold);
      expect(sold, isNotEmpty);
    });
  });
}
