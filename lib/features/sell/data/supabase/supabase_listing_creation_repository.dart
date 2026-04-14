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

  // Column names — shared between insert maps and row parsing.
  static const _kTitle = 'title';
  static const _kDescription = 'description';
  static const _kPriceCents = 'price_cents';
  static const _kCondition = 'condition';
  static const _kCategoryId = 'category_id';
  static const _kImageUrls = 'image_urls';
  static const _kLocation = 'location';
  static const _kIsActive = 'is_active';
  static const _kIsSold = 'is_sold';
  static const _kShippingCarrier = 'shipping_carrier';
  static const _kWeightRange = 'weight_range';

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
      isActive: true,
      fields: {
        _kTitle: title,
        _kDescription: description,
        _kPriceCents: priceInCents,
        _kCondition: condition.toDb(),
        _kCategoryId: categoryId,
        _kImageUrls: imageUrls,
        _kLocation: location,
        _kShippingCarrier: shippingCarrier.toDb(),
        if (weightRange != null) _kWeightRange: weightRange.toDb(),
      },
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
      isActive: false,
      fields: {
        _kTitle: title.isEmpty ? 'Draft' : title,
        _kDescription: description.isEmpty ? 'Draft listing' : description,
        // DB CHECK constraint requires price_cents > 0; use 1 as sentinel
        // for "not yet set". The publish flow (create) enforces real prices.
        _kPriceCents: priceInCents > 0 ? priceInCents : 1,
        _kCondition: (condition ?? ListingCondition.good).toDb(),
        _kCategoryId: categoryId ?? _uncategorisedId,
        _kImageUrls: imageUrls,
        _kLocation: location,
        _kShippingCarrier: shippingCarrier.toDb(),
        if (weightRange != null) _kWeightRange: weightRange.toDb(),
      },
    );
  }

  Future<ListingEntity> _insert({
    required bool isActive,
    required Map<String, Object?> fields,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');
    final userId = currentUser.id;

    try {
      final response =
          await _client
              .from(_table)
              .insert({
                'seller_id': userId,
                ...fields,
                _kIsActive: isActive,
                _kIsSold: false,
              })
              .select()
              .single();

      final sellerName =
          currentUser.userMetadata?['display_name'] as String? ?? '';
      return _entityFromRow(response, userId, sellerName);
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to ${isActive ? "create" : "save draft"}: ${e.message}',
      );
    }
  }

  static ListingEntity _entityFromRow(
    Map<String, dynamic> json,
    String sellerId,
    String sellerName,
  ) {
    return ListingEntity(
      id: json['id'] as String,
      title: json[_kTitle] as String,
      description: json[_kDescription] as String,
      priceInCents: json[_kPriceCents] as int,
      sellerId: sellerId,
      sellerName: sellerName,
      condition: ListingCondition.fromDb(
        (json[_kCondition] as String?) ?? 'good',
      ),
      categoryId: (json[_kCategoryId] as String?) ?? '',
      imageUrls:
          (json[_kImageUrls] as List<dynamic>?)?.whereType<String>().toList() ??
          [],
      location: json[_kLocation] as String?,
      status: _statusFromBooleans(
        isActive: json[_kIsActive] as bool? ?? true,
        isSold: json[_kIsSold] as bool? ?? false,
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
