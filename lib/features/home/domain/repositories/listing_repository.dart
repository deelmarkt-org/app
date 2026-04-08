import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Listing repository interface — domain layer.
///
/// Implementations: MockListingRepository (Phase 1), SupabaseListingRepository (Phase 4).
/// Swapped via Riverpod provider overrides — no conditional logic.
abstract class ListingRepository {
  /// Get recent listings for home feed.
  Future<List<ListingEntity>> getRecent({int limit = 20});

  /// Get listings near a location.
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  });

  /// Get a single listing by ID.
  Future<ListingEntity?> getById(String id);

  /// Search listings (backend-agnostic — works with FTS, Meilisearch, or ES).
  ///
  /// Use [categoryIds] to filter by multiple categories in a single query
  /// (avoids N+1 when expanding L1 → L2 categories). If both [categoryId]
  /// and [categoryIds] are provided, [categoryIds] takes precedence.
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
  });

  /// Toggle favourite status.
  Future<ListingEntity> toggleFavourite(String listingId);

  /// Get user's favourited listings.
  Future<List<ListingEntity>> getFavourites();

  /// Get listings by a specific user.
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  });
}

/// Search result with pagination metadata.
class ListingSearchResult extends Equatable {
  const ListingSearchResult({
    required this.listings,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<ListingEntity> listings;
  final int total;
  final int offset;
  final int limit;

  bool get hasMore => offset + listings.length < total;

  @override
  List<Object?> get props => [listings, total, offset, limit];
}
