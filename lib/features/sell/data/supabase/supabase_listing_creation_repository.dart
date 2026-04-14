import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';

/// Supabase implementation of [ListingCreationRepository].
///
/// Inserts into the `listings` table. Published listings have
/// `is_active = true, is_sold = false`. Drafts have `is_active = false`.
///
/// Reference: migration 20260329161637_phase_a (listings table definition)
class SupabaseListingCreationRepository implements ListingCreationRepository {
  const SupabaseListingCreationRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'listings';
  static const _uncategorisedId = 'c1000000-0000-0000-0000-000000000008';

  @override
  Future<ListingEntity> create({
    required String title,
    required String description,
    required int priceInCents,
    required ListingCondition condition,
    required String categoryId,
    required List<String> imageUrls,
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    return _insert(
      title: title,
      description: description,
      priceInCents: priceInCents,
      condition: condition,
      categoryId: categoryId,
      imageUrls: imageUrls,
      location: location,
      isActive: true,
    );
  }

  @override
  Future<ListingEntity> saveDraft({
    required String title,
    String description = '',
    int priceInCents = 0,
    ListingCondition? condition,
    String? categoryId,
    List<String> imageUrls = const [],
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    return _insert(
      title: title.isEmpty ? 'Draft' : title,
      description: description.isEmpty ? 'Draft listing' : description,
      priceInCents: priceInCents > 0 ? priceInCents : 1,
      condition: condition ?? ListingCondition.good,
      categoryId: categoryId ?? _uncategorisedId,
      imageUrls: imageUrls,
      location: location,
      isActive: false,
    );
  }

  Future<ListingEntity> _insert({
    required String title,
    required String description,
    required int priceInCents,
    required ListingCondition condition,
    required String categoryId,
    required List<String> imageUrls,
    required bool isActive,
    String? location,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final response =
          await _client
              .from(_table)
              .insert({
                'seller_id': userId,
                'title': title,
                'description': description,
                'price_cents': priceInCents,
                'condition': condition.toDb(),
                'category_id': categoryId,
                'image_urls': imageUrls,
                'location': location,
                'is_active': isActive,
                'is_sold': false,
              })
              .select()
              .single();

      return _entityFromRow(response, userId);
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to ${isActive ? "create" : "save draft"}: ${e.message}',
      );
    }
  }

  static ListingEntity _entityFromRow(
    Map<String, dynamic> json,
    String sellerId,
  ) {
    return ListingEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priceInCents: json['price_cents'] as int,
      sellerId: sellerId,
      sellerName: '',
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
      status: _statusFromBooleans(
        isActive: json['is_active'] as bool? ?? true,
        isSold: json['is_sold'] as bool? ?? false,
      ),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  static ListingStatus _statusFromBooleans({
    required bool isActive,
    required bool isSold,
  }) {
    if (isSold) return ListingStatus.sold;
    if (!isActive) return ListingStatus.draft;
    return ListingStatus.active;
  }
}
