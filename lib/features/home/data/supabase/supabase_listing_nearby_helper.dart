import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/home/data/dto/listing_dto.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Extracted helper for the [SupabaseListingRepository.getNearby] flow
/// (B-64 — Tier-1 retrospective decomposition; mirrors P-54 pattern).
///
/// Two-phase query:
///   1. Call the `nearby_listings` RPC for distance-sorted (id, distance) pairs.
///   2. Re-fetch full listing rows for those ids from `listings_with_favourites`,
///      enrich with the distance map, sort by distance.
///
/// Pure helper — no state, no caching. Safe to instantiate per call.
///
/// Reference: docs/epics/E01-listing-management.md §Distance Search
class SupabaseListingNearbyHelper {
  const SupabaseListingNearbyHelper(this._client, this._view);

  final SupabaseClient _client;
  final String _view;

  static const _colListingId = 'listing_id';

  /// Returns listings within [radiusKm] of (lat, lon), enriched with
  /// per-row `distanceKm`, ordered by ascending distance.
  Future<List<ListingEntity>> fetch({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int limit,
  }) async {
    final distanceMap = await _fetchIdDistanceMap(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
    if (distanceMap.isEmpty) return const [];

    final response = await _client
        .from(_view)
        .select()
        .inFilter('id', distanceMap.keys.toList());
    final listings = ListingDto.fromJsonList(response);

    return listings
        .map((l) => l.copyWith(distanceKm: distanceMap[l.id]))
        .toList()
      ..sort(
        (a, b) => (a.distanceKm ?? double.infinity).compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );
  }

  /// Phase 1: call the `nearby_listings` RPC and parse its `(id, distance_km)`
  /// rows into a map. Returns an empty map if the RPC is empty or the response
  /// shape is unexpected.
  Future<Map<String, double>> _fetchIdDistanceMap({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int limit,
  }) async {
    final nearbyIds = await _client.rpc(
      'nearby_listings',
      params: {
        'user_lat': latitude,
        'user_lon': longitude,
        'radius_km': radiusKm,
        'max_results': limit,
      },
    );
    if (nearbyIds == null) return const {};

    final idsList = nearbyIds is List ? nearbyIds : const [];
    if (idsList.isEmpty) return const {};

    final out = <String, double>{};
    for (final row in idsList) {
      // Guarded type narrowing — pana review (PR #268 SonarCloud finding):
      // an unguarded `as Map<String, dynamic>` would throw TypeError if the
      // RPC returns an unexpected shape. Skip malformed rows instead so the
      // caller's catch(PostgrestException) is not asked to handle a runtime
      // cast failure.
      if (row is! Map) continue;
      final id = row[_colListingId];
      final dist = row['distance_km'];
      if (id is String && dist is num) {
        out[id] = dist.toDouble();
      }
    }
    return out;
  }
}
