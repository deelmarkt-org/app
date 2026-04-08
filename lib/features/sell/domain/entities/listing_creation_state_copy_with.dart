import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// [copyWith] extension for [ListingCreationState].
///
/// Kept in a companion file to hold both files under the 100-line entity
/// limit (CLAUDE.md §2.1).
///
/// Uses `T? Function()?` for nullable fields to distinguish
/// "keep current value" (omit / pass null) from "clear to null"
/// (pass `() => null`).
extension ListingCreationStateCopyWith on ListingCreationState {
  ListingCreationState copyWith({
    ListingCreationStep? step,
    List<String>? imageFiles,
    String? title,
    String? description,
    String? Function()? categoryL1Id,
    String? Function()? categoryL2Id,
    ListingCondition? Function()? condition,
    int? priceInCents,
    ShippingCarrier? shippingCarrier,
    WeightRange? Function()? weightRange,
    String? Function()? location,
    bool? isLoading,
    String? Function()? errorKey,
    String? Function()? createdListingId,
  }) {
    return ListingCreationState(
      step: step ?? this.step,
      imageFiles: imageFiles ?? this.imageFiles,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryL1Id: categoryL1Id != null ? categoryL1Id() : this.categoryL1Id,
      categoryL2Id: categoryL2Id != null ? categoryL2Id() : this.categoryL2Id,
      condition: condition != null ? condition() : this.condition,
      priceInCents: priceInCents ?? this.priceInCents,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
      weightRange: weightRange != null ? weightRange() : this.weightRange,
      location: location != null ? location() : this.location,
      isLoading: isLoading ?? this.isLoading,
      errorKey: errorKey != null ? errorKey() : this.errorKey,
      createdListingId:
          createdListingId != null ? createdListingId() : this.createdListingId,
    );
  }
}
