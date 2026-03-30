import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listing_repository.dart';
import '../dto/listing_dto.dart';

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
    final response = await _client
        .from(_view)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return ListingDto.fromJsonList(response);
  }

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async {
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

    if (nearbyIds == null || (nearbyIds as List).isEmpty) return [];

    // Build a map of id → distance for enrichment
    final distanceMap = <String, double>{};
    for (final row in nearbyIds) {
      distanceMap[row['listing_id'] as String] =
          (row['distance_km'] as num).toDouble();
    }

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
  }

  @override
  Future<ListingEntity?> getById(String id) async {
    final response =
        await _client.from(_view).select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ListingDto.fromJson(response);
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

    // PostgREST doesn't return total count with range queries.
    // Use response length as approximation; exact count needs separate query.
    final listings = ListingDto.fromJsonList(response);

    return ListingSearchResult(
      listings: listings,
      total:
          listings.length < limit
              ? offset + listings.length
              : offset + limit + 1,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<ListingEntity> toggleFavourite(String listingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Check if already favourited
    final existing =
        await _client
            .from('favourites')
            .select('id')
            .eq('user_id', userId)
            .eq('listing_id', listingId)
            .maybeSingle();

    if (existing != null) {
      // Remove favourite
      await _client
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } else {
      // Add favourite
      await _client.from('favourites').insert({
        'user_id': userId,
        'listing_id': listingId,
      });
    }

    // Return updated listing
    final updated = await getById(listingId);
    return updated!;
  }

  @override
  Future<List<ListingEntity>> getFavourites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Join favourites → listings via the view
    final favIds = await _client
        .from('favourites')
        .select('listing_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (favIds.isEmpty) return [];

    final ids = favIds.map((f) => f['listing_id'] as String).toList();
    final response = await _client.from(_view).select().inFilter('id', ids);

    return ListingDto.fromJsonList(response);
  }
}
