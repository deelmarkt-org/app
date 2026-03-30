import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Mock listing repository — returns static data for Phase 1-2 widget development.
///
/// Swapped for SupabaseListingRepository in Phase 4 via Riverpod override.
/// Note: not thread-safe — single-isolate mock use only.
class MockListingRepository implements ListingRepository {
  @visibleForTesting
  Set<String> favouriteIds = const <String>{};

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockListings.take(limit).toList();
  }

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockListings
        .where((l) => l.distanceKm != null && l.distanceKm! <= radiusKm)
        .take(limit)
        .toList();
  }

  @override
  Future<ListingEntity?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _mockListings.firstWhere((l) => l.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<ListingSearchResult> search({
    required String query,
    String? categoryId,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    int offset = 0,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final lowerQuery = query.toLowerCase();
    final results =
        _mockListings.where((l) {
          final matchesQuery =
              l.title.toLowerCase().contains(lowerQuery) ||
              l.description.toLowerCase().contains(lowerQuery);
          final matchesCategory =
              categoryId == null || l.categoryId == categoryId;
          final matchesPrice =
              (minPriceCents == null || l.priceInCents >= minPriceCents) &&
              (maxPriceCents == null || l.priceInCents <= maxPriceCents);
          final matchesCondition =
              condition == null || l.condition == condition;
          return matchesQuery &&
              matchesCategory &&
              matchesPrice &&
              matchesCondition;
        }).toList();

    return ListingSearchResult(
      listings: results.skip(offset).take(limit).toList(),
      total: results.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<ListingEntity> toggleFavourite(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (favouriteIds.contains(listingId)) {
      favouriteIds = {...favouriteIds}..remove(listingId);
    } else {
      favouriteIds = {...favouriteIds, listingId};
    }
    final listing = _mockListings.firstWhere((l) => l.id == listingId);
    return listing.copyWith(isFavourited: favouriteIds.contains(listingId));
  }

  @override
  Future<List<ListingEntity>> getFavourites() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockListings.where((l) => favouriteIds.contains(l.id)).toList();
  }
}

const _sampleImageUrl =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';

final _mockListings = [
  ListingEntity(
    id: 'listing-001',
    title: 'Giant Defy Advanced 2 Racefiets',
    description:
        'Carbon frame, Shimano 105 groepset. 2 jaar oud, weinig gereden.',
    priceInCents: 89500,
    sellerId: 'user-001',
    sellerName: 'Jan de Vries',
    condition: ListingCondition.good,
    categoryId: 'cat-sport',
    imageUrls: const [_sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 3.2,
    createdAt: DateTime(2026, 3, 20),
  ),
  ListingEntity(
    id: 'listing-002',
    title: 'iPhone 15 Pro 256GB',
    description: 'Inclusief originele doos en oplader. Geen kratjes.',
    priceInCents: 75000,
    sellerId: 'user-002',
    sellerName: 'Maria Jansen',
    condition: ListingCondition.likeNew,
    categoryId: 'cat-electronics',
    imageUrls: const [_sampleImageUrl],
    location: 'Rotterdam',
    distanceKm: 12.5,
    createdAt: DateTime(2026, 3, 22),
  ),
  ListingEntity(
    id: 'listing-003',
    title: 'IKEA Kallax Kast 4x4',
    description: 'Wit, goede staat. Zelf ophalen in Utrecht.',
    priceInCents: 4500,
    sellerId: 'user-003',
    sellerName: 'Pieter Bakker',
    condition: ListingCondition.fair,
    categoryId: 'cat-home',
    imageUrls: const [_sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 8.0,
    createdAt: DateTime(2026, 3, 24),
  ),
  ListingEntity(
    id: 'listing-004',
    title: 'Nike Air Max 90 maat 43',
    description:
        'Nieuw met labels, nooit gedragen. Cadeau gekregen maar verkeerde maat.',
    priceInCents: 8900,
    sellerId: 'user-004',
    sellerName: 'Sophie Visser',
    condition: ListingCondition.newWithTags,
    categoryId: 'cat-clothing',
    imageUrls: const [_sampleImageUrl],
    location: 'Den Haag',
    distanceKm: 5.1,
    createdAt: DateTime(2026, 3, 25),
  ),
];
