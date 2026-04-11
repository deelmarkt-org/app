import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Contract for persisting listing creation data.
///
/// Domain layer interface — implementations live in the data layer.
/// No Flutter or Supabase imports allowed here.
abstract class ListingCreationRepository {
  /// Creates and publishes a new listing.
  ///
  /// All required fields must be provided.
  /// [imageUrls] are Cloudinary delivery URLs of already-uploaded images
  /// (the upload-on-pick pipeline runs in the presentation layer).
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
  });

  /// Saves a draft listing with partial data.
  ///
  /// Most fields are optional — the user can save at any point
  /// during the creation flow and resume later.
  /// [imageUrls] are Cloudinary delivery URLs of already-uploaded images.
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
  });
}
