import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/home/data/dto/listing_dto.dart';

/// Supabase implementation of [ListingRepository].
///
/// Queries the `listings_with_favourites` view which includes seller info
/// and per-user favourited flag. Uses PostgREST for all queries.
///
/// Reference: CLAUDE.md §1.2, docs/epics/E01-listing-management.md
class SupabaseListingRepository implements ListingRepository {
  const SupabaseListingRepository(this._client);

  final SupabaseClient _client;

  /// View name — includes seller join + is_favourited.
  static const _view = 'listings_with_favourites';

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async {
    try {
      final response = await _client
          .from(_view)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return ListingDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch recent listings: ${e.message}');
    }
  }

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async {
    try {
      // Use the nearby_listings RPC for distance-sorted results
      final nearbyIds = await _client.rpc(
        'nearby_listings',
        params: {
          'user_lat': latitude,
          'user_lon': longitude,
          'radius_km': radiusKm,
          'max_results': limit,
        },
      );

      if (nearbyIds == null) return [];
      final idsList = nearbyIds is List ? nearbyIds : [];
      if (idsList.isEmpty) return [];

      // Build a map of id → distance for enrichment
      final distanceMap = <String, double>{};
      for (final row in idsList) {
        final typedRow = row as Map<String, dynamic>;
        final id = typedRow['listing_id'];
        final dist = typedRow['distance_km'];
        if (id is String && dist is num) {
          distanceMap[id] = dist.toDouble();
        }
      }

      if (distanceMap.isEmpty) return [];

      // Fetch full listing data for these IDs
      final ids = distanceMap.keys.toList();
      final response = await _client.from(_view).select().inFilter('id', ids);

      final listings = ListingDto.fromJsonList(response);

      // Enrich with distance and sort by distance
      return listings
          .map((l) => l.copyWith(distanceKm: distanceMap[l.id]))
          .toList()
        ..sort(
          (a, b) => (a.distanceKm ?? double.infinity).compareTo(
            b.distanceKm ?? double.infinity,
          ),
        );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch nearby listings: ${e.message}');
    }
  }

  @override
  Future<ListingEntity?> getById(String id) async {
    try {
      final response =
          await _client.from(_view).select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return ListingDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch listing $id: ${e.message}');
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
    try {
      var request = _client.from(_view).select();

      // Full-text search using the Dutch tsvector
      if (query.isNotEmpty) {
        request = request.textSearch(
          'search_vector',
          query,
          config: 'dutch',
          type: TextSearchType.websearch,
        );
      }

      if (categoryId != null) {
        request = request.eq('category_id', categoryId);
      }
      if (minPriceCents != null) {
        request = request.gte('price_cents', minPriceCents);
      }
      if (maxPriceCents != null) {
        request = request.lte('price_cents', maxPriceCents);
      }
      if (condition != null) {
        request = request.eq('condition', condition.toDb());
      }

      final response = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final listings = ListingDto.fromJsonList(response);

      // Pagination: if we got fewer items than limit, we've reached the end.
      // Otherwise, signal there may be more items.
      return ListingSearchResult(
        listings: listings,
        total: offset + listings.length + (listings.length == limit ? 1 : 0),
        offset: offset,
        limit: limit,
      );
    } on PostgrestException catch (e) {
      throw Exception('Search failed: ${e.message}');
    }
  }

  @override
  Future<ListingEntity> toggleFavourite(String listingId) async {
    try {
      // Atomic toggle via RPC — single round-trip instead of 3
      await _client.rpc(
        'toggle_favourite',
        params: {'p_listing_id': listingId},
      );

      // Return updated listing
      final updated = await getById(listingId);
      if (updated == null) {
        throw Exception('Listing $listingId not found after favourite toggle');
      }
      return updated;
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle favourite: ${e.message}');
    }
  }

  @override
  Future<List<ListingEntity>> getFavourites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final favIds = await _client
          .from('favourites')
          .select('listing_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (favIds.isEmpty) return [];

      final ids = favIds.map((f) => f['listing_id'] as String).toList();
      final response = await _client.from(_view).select().inFilter('id', ids);

      return ListingDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch favourites: ${e.message}');
    }
  }

  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async {
    try {
      var query = _client.from(_view).select().eq('seller_id', userId);
      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return ListingDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user listings: ${e.message}');
    }
  }
}
