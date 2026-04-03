import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Contract for persisting listing creation data.
///
/// Domain layer interface — implementations live in the data layer.
/// No Flutter or Supabase imports allowed here.
abstract class ListingCreationRepository {
  /// Creates and publishes a new listing.
  ///
  /// All required fields must be provided.
  /// [imagePaths] are local file paths that the data layer uploads.
  Future<ListingEntity> create({
    required String title,
    required String description,
    required int priceInCents,
    required ListingCondition condition,
    required String categoryId,
    required List<String> imagePaths,
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  });

  /// Saves a draft listing with partial data.
  ///
  /// Most fields are optional — the user can save at any point
  /// during the creation flow and resume later.
  Future<ListingEntity> saveDraft({
    required String title,
    String description = '',
    int priceInCents = 0,
    ListingCondition? condition,
    String? categoryId,
    List<String> imagePaths = const [],
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  });
}
