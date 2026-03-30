import '../../domain/entities/listing_entity.dart';

/// DTO for converting Supabase REST JSON to [ListingEntity].
///
/// All parsing is defensive — malformed JSON throws [FormatException]
/// with descriptive message instead of opaque TypeError.
class ListingDto {
  const ListingDto._();

  /// Parse a Supabase JSON row from `listings_with_favourites` view.
  static ListingEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final priceCents = json['price_cents'];
    final createdAtRaw = json['created_at'];

    if (id is! String ||
        title is! String ||
        description is! String ||
        priceCents is! int ||
        createdAtRaw is! String) {
      throw FormatException(
        'ListingDto.fromJson: missing or invalid required fields',
      );
    }

    return ListingEntity(
      id: id,
      title: title,
      description: description,
      priceInCents: priceCents,
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
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }

  /// Convert [ListingEntity] to Supabase INSERT/UPDATE JSON.
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

  /// Parse a list of JSON rows. Skips malformed entries.
  static List<ListingEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
