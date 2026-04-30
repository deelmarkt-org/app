import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/home/data/dto/listing_dto.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_listing_nearby_helper.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Supabase implementation of [ListingRepository] (PostgREST against the
/// `listings_with_favourites` view). Distance-search (`getNearby`) is
/// delegated to [SupabaseListingNearbyHelper] (B-64).
///
/// Reference: CLAUDE.md §1.2, docs/epics/E01-listing-management.md
class SupabaseListingRepository implements ListingRepository {
  SupabaseListingRepository(this._client)
    : _nearbyHelper = SupabaseListingNearbyHelper(_client, _view);

  final SupabaseClient _client;
  final SupabaseListingNearbyHelper _nearbyHelper;

  /// View name — includes seller join + is_favourited.
  static const _view = 'listings_with_favourites';
  static const _colCreatedAt = 'created_at';
  static const _colListingId = 'listing_id';

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async {
    try {
      final response = await _client
          .from(_view)
          .select()
          .order(_colCreatedAt, ascending: false)
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
      return await _nearbyHelper.fetch(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
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
    List<String>? categoryIds,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    String? sortBy,
    bool ascending = false,
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

      // categoryIds takes precedence over categoryId (avoids N+1).
      if (categoryIds != null && categoryIds.isNotEmpty) {
        request = request.inFilter('category_id', categoryIds);
      } else if (categoryId != null) {
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

      final orderColumn = sortBy ?? _colCreatedAt;
      final response = await request
          .order(orderColumn, ascending: ascending)
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
          .select(_colListingId)
          .eq('user_id', userId)
          .order(_colCreatedAt, ascending: false);

      if (favIds.isEmpty) return [];

      final ids = favIds.map((f) => f[_colListingId] as String).toList();
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
        query = query.lt(_colCreatedAt, cursor);
      }
      final response = await query
          .order(_colCreatedAt, ascending: false)
          .limit(limit);
      return ListingDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user listings: ${e.message}');
    }
  }
}
