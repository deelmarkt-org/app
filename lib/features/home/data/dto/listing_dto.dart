import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// DTO for converting Supabase REST JSON to [ListingEntity].
///
/// All parsing is defensive — malformed JSON throws [FormatException]
/// with descriptive message instead of opaque TypeError.
class ListingDto {
  const ListingDto._();

  /// Fires the "escrow_eligible missing" warning **at most once per
  /// process**. List screens pull 20+ listings per render, so without a
  /// guard the warning would flood Crashlytics on a stale-view deploy.
  /// The first hit is the one that needs attention; after that it is noise.
  static bool _missingEscrowWarned = false;

  /// Parse a Supabase JSON row from `listings_with_favourites` view.
  static ListingEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final priceCents = json['price_cents'];
    final createdAtRaw = json['created_at'];

    final originalPriceCents = json['original_price_cents'];

    if (id is! String ||
        title is! String ||
        description is! String ||
        priceCents is! int ||
        createdAtRaw is! String ||
        (originalPriceCents != null && originalPriceCents is! int)) {
      throw const FormatException(
        'ListingDto.fromJson: missing or invalid required fields',
      );
    }

    return ListingEntity(
      id: id,
      title: title,
      description: description,
      priceInCents: priceCents,
      originalPriceInCents: originalPriceCents as int?,
      sellerId: (json['seller_id'] as String?) ?? '',
      sellerName: (json['seller_name'] as String?) ?? 'Verkoper',
      condition: ListingCondition.fromDb(
        (json['condition'] as String?) ?? 'good',
      ),
      categoryId: (json['category_id'] as String?) ?? '',
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      location: json['location'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isFavourited: (json['is_favourited'] as bool?) ?? false,
      qualityScore: json['quality_score'] as int?,
      status: ListingStatus.fromDb((json['status'] as String?) ?? 'active'),
      viewCount: (json['view_count'] as int?) ?? 0,
      favouriteCount: (json['favourite_count'] as int?) ?? 0,
      isEscrowAvailable: _parseEscrowEligible(json),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }

  /// Fail-closed parse of the `escrow_eligible` column.
  ///
  /// Returns `false` whenever the key is missing, null, or not a boolean.
  /// Logs a warning **once per process** when the key is absent because
  /// that signals the `listings_with_favourites` view or RPC projection
  /// is stale — something humans should investigate, even though the
  /// user-facing behaviour (badge hidden) is safe. ADR-023.
  static bool _parseEscrowEligible(Map<String, dynamic> json) {
    if (!json.containsKey('escrow_eligible')) {
      if (!_missingEscrowWarned) {
        _missingEscrowWarned = true;
        AppLogger.warning(
          'escrow_eligible missing from listing JSON — defaulting false. '
          'Check listings_with_favourites view column list.',
          tag: 'ListingDto',
        );
      }
      return false;
    }
    final raw = json['escrow_eligible'];
    return raw is bool ? raw : false;
  }

  /// Convert [ListingEntity] to Supabase INSERT/UPDATE JSON.
  static Map<String, dynamic> toJson(ListingEntity entity) {
    return {
      'title': entity.title,
      'description': entity.description,
      'price_cents': entity.priceInCents,
      'original_price_cents': entity.originalPriceInCents,
      'seller_id': entity.sellerId,
      'condition': entity.condition.toDb(),
      'category_id': entity.categoryId,
      'image_urls': entity.imageUrls,
      'location': entity.location,
      'status': entity.status.toDb(),
    };
  }

  /// Parse a list of JSON rows. Skips malformed entries.
  static List<ListingEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
