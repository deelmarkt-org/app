import '../../domain/entities/listing_entity.dart';

/// DTO for converting Supabase REST JSON to [ListingEntity].
///
/// Maps the `listings_with_favourites` view which includes seller info
/// and per-user favourited flag via auth.uid().
///
/// Reference: supabase/migrations/20260329192715 (view definition)
class ListingDto {
  const ListingDto._();

  /// Parse a Supabase JSON row from `listings_with_favourites` view.
  static ListingEntity fromJson(Map<String, dynamic> json) {
    return ListingEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priceInCents: json['price_cents'] as int,
      sellerId: json['seller_id'] as String,
      sellerName: (json['seller_name'] as String?) ?? 'Verkoper',
      condition: ListingCondition.fromDb(json['condition'] as String),
      categoryId: json['category_id'] as String,
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isFavourited: (json['is_favourited'] as bool?) ?? false,
      qualityScore: json['quality_score'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert [ListingEntity] to Supabase INSERT/UPDATE JSON.
  /// Only includes writable fields (not view-computed fields).
  static Map<String, dynamic> toJson(ListingEntity entity) {
    return {
      'title': entity.title,
      'description': entity.description,
      'price_cents': entity.priceInCents,
      'seller_id': entity.sellerId,
      'condition': entity.condition.toDb(),
      'category_id': entity.categoryId,
      'image_urls': entity.imageUrls,
      'location': entity.location,
    };
  }

  /// Parse a list of JSON rows.
  static List<ListingEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
