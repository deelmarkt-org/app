import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/domain/entities/shipping_types.dart';

export 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
export 'package:deelmarkt/features/sell/domain/entities/shipping_types.dart';

/// Steps in the listing creation wizard.
enum ListingCreationStep { photos, details, quality, publishing, success }

/// Immutable state for the listing creation wizard.
///
/// Pure domain entity — no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing.
///
/// [copyWith] lives in the companion extension file
/// `listing_creation_state_copy_with.dart` to keep both files under the
/// 100-line entity limit (CLAUDE.md §2.1).
class ListingCreationState extends Equatable {
  const ListingCreationState({
    this.step = ListingCreationStep.photos,
    this.imageFiles = const [],
    this.title = '',
    this.description = '',
    this.categoryL1Id,
    this.categoryL2Id,
    this.condition,
    this.priceInCents = 0,
    this.shippingCarrier = ShippingCarrier.none,
    this.weightRange,
    this.location,
    this.isLoading = false,
    this.errorKey,
    this.createdListingId,
  });

  factory ListingCreationState.initial() => const ListingCreationState();

  final ListingCreationStep step;

  /// Picked images with per-item upload state.
  /// Order is preserved and is the primary key for rendering; ids are the
  /// primary key for state patches (immune to reorder/remove races).
  final List<SellImage> imageFiles;
  final String title;
  final String description;
  final String? categoryL1Id;
  final String? categoryL2Id;
  final ListingCondition? condition;

  /// Price in euro cents (e.g. 4500 = EUR 45.00).
  final int priceInCents;

  final ShippingCarrier shippingCarrier;
  final WeightRange? weightRange;

  /// Postcode for pickup location.
  final String? location;

  final bool isLoading;

  /// L10n key for the current error, null when no error.
  final String? errorKey;

  /// ID of the successfully created listing, used for navigation.
  final String? createdListingId;

  /// Returns true if any field has been modified from its default value.
  bool get hasUnsavedData =>
      imageFiles.isNotEmpty ||
      title.isNotEmpty ||
      description.isNotEmpty ||
      categoryL1Id != null ||
      categoryL2Id != null ||
      condition != null ||
      priceInCents != 0 ||
      shippingCarrier != ShippingCarrier.none ||
      weightRange != null ||
      location != null;

  @override
  List<Object?> get props => [
    step,
    imageFiles,
    title,
    description,
    categoryL1Id,
    categoryL2Id,
    condition,
    priceInCents,
    shippingCarrier,
    weightRange,
    location,
    isLoading,
    errorKey,
    createdListingId,
  ];
}
