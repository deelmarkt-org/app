import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

import 'package:deelmarkt/features/home/data/mock/mock_listing_data.dart';

/// Mock listing repository — returns static data for Phase 1-2 widget development.
///
/// Swapped for SupabaseListingRepository in Phase 4 via Riverpod override.
/// Data defined in `mock_listing_data.dart`.
/// Note: not thread-safe — single-isolate mock use only.
class MockListingRepository implements ListingRepository {
  @visibleForTesting
  Set<String> favouriteIds = const <String>{};

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockListings.take(limit).toList();
  }

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockListings
        .where((l) => l.distanceKm != null && l.distanceKm! <= radiusKm)
        .take(limit)
        .toList();
  }

  @override
  Future<ListingEntity?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return mockListings.firstWhere((l) => l.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<ListingSearchResult> search({
    required String query,
    String? categoryId,
    List<String>? categoryIds,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    String? sortBy,
    bool ascending = false,
    int offset = 0,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final lowerQuery = query.toLowerCase();
    final effectiveIds =
        categoryIds ?? (categoryId != null ? [categoryId] : null);
    final results =
        mockListings.where((l) {
          final matchesQuery =
              l.title.toLowerCase().contains(lowerQuery) ||
              l.description.toLowerCase().contains(lowerQuery);
          final matchesCategory =
              effectiveIds == null || effectiveIds.contains(l.categoryId);
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

    if (sortBy == 'price_cents') {
      results.sort(
        (a, b) =>
            ascending
                ? a.priceInCents.compareTo(b.priceInCents)
                : b.priceInCents.compareTo(a.priceInCents),
      );
    } else if (sortBy == 'created_at') {
      results.sort(
        (a, b) =>
            ascending
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt),
      );
    }

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
    final listing = mockListings.firstWhere((l) => l.id == listingId);
    return listing.copyWith(isFavourited: favouriteIds.contains(listingId));
  }

  @override
  Future<List<ListingEntity>> getFavourites() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mockListings.where((l) => favouriteIds.contains(l.id)).toList();
  }

  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockListings.where((l) => l.sellerId == userId).take(limit).toList();
  }
}
