import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Steps in the listing creation wizard.
enum ListingCreationStep { photos, details, quality, publishing, success }

/// Supported shipping carriers — matches DB `shipping_carrier` enum.
enum ShippingCarrier {
  postnl,
  dhl,
  none;

  /// Convert to DB snake_case value.
  String toDb() => name;
}

/// Package weight range for shipping cost calculation.
///
/// Labels are in Dutch for display in the shipping step.
enum WeightRange {
  zeroToTwo,
  twoToFive,
  fiveToTen,
  tenToTwentyThree,
  twentyThreeToThirtyOne;

  /// Dutch label for display in the UI.
  String get label => switch (this) {
    WeightRange.zeroToTwo => '0-2 kg',
    WeightRange.twoToFive => '2-5 kg',
    WeightRange.fiveToTen => '5-10 kg',
    WeightRange.tenToTwentyThree => '10-23 kg',
    WeightRange.twentyThreeToThirtyOne => '23-31 kg',
  };
}

/// Immutable state for the listing creation wizard.
///
/// Pure domain entity — no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing.
///
/// Uses the `String? Function()?` pattern for nullable [errorKey]
/// in [copyWith] to distinguish "keep current value" from "clear to null".
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

  /// Creates the initial state with all defaults.
  factory ListingCreationState.initial() => const ListingCreationState();

  /// Current step in the creation wizard.
  final ListingCreationStep step;

  /// Local file paths of selected images.
  final List<String> imageFiles;

  /// Listing title.
  final String title;

  /// Listing description.
  final String description;

  /// Top-level category ID.
  final String? categoryL1Id;

  /// Sub-category ID.
  final String? categoryL2Id;

  /// Item condition.
  final ListingCondition? condition;

  /// Price in euro cents (e.g. 4500 = EUR 45.00).
  final int priceInCents;

  /// Selected shipping carrier.
  final ShippingCarrier shippingCarrier;

  /// Package weight range for shipping.
  final WeightRange? weightRange;

  /// Postcode for pickup location.
  final String? location;

  /// Whether an async operation is in progress.
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

  /// Creates a copy with the given fields replaced.
  ///
  /// Uses `String? Function()?` for [errorKey] to allow clearing to null:
  /// - Omit or pass null: keeps current value
  /// - Pass `() => null`: clears to null
  /// - Pass `() => 'sell.someError'`: sets new error key
  ListingCreationState copyWith({
    ListingCreationStep? step,
    List<String>? imageFiles,
    String? title,
    String? description,
    String? categoryL1Id,
    String? categoryL2Id,
    ListingCondition? condition,
    int? priceInCents,
    ShippingCarrier? shippingCarrier,
    WeightRange? weightRange,
    String? location,
    bool? isLoading,
    String? Function()? errorKey,
    String? createdListingId,
  }) {
    return ListingCreationState(
      step: step ?? this.step,
      imageFiles: imageFiles ?? this.imageFiles,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryL1Id: categoryL1Id ?? this.categoryL1Id,
      categoryL2Id: categoryL2Id ?? this.categoryL2Id,
      condition: condition ?? this.condition,
      priceInCents: priceInCents ?? this.priceInCents,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
      weightRange: weightRange ?? this.weightRange,
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      errorKey: errorKey != null ? errorKey() : this.errorKey,
      createdListingId: createdListingId ?? this.createdListingId,
    );
  }

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
