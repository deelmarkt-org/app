import 'package:equatable/equatable.dart';

/// Marketplace listing — a second-hand item for sale.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// All monetary values in cents to avoid floating-point errors.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E01-listing-management.md
class ListingEntity extends Equatable {
  const ListingEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priceInCents,
    required this.sellerId,
    required this.sellerName,
    required this.condition,
    required this.categoryId,
    required this.imageUrls,
    required this.createdAt,
    this.location,
    this.distanceKm,
    this.isFavourited = false,
    this.qualityScore,
  });

  final String id;
  final String title;
  final String description;

  /// Price in cents (e.g. 4500 = €45.00). Mollie API compatible.
  final int priceInCents;

  final String sellerId;
  final String sellerName;
  final ListingCondition condition;
  final String categoryId;
  final List<String> imageUrls;
  final String? location;
  final double? distanceKm;
  final bool isFavourited;

  /// Listing quality score (0–100) from quality-score Edge Function.
  final int? qualityScore;

  final DateTime createdAt;

  ListingEntity copyWith({
    String? id,
    String? title,
    String? description,
    int? priceInCents,
    String? sellerId,
    String? sellerName,
    ListingCondition? condition,
    String? categoryId,
    List<String>? imageUrls,
    String? location,
    double? distanceKm,
    bool? isFavourited,
    int? qualityScore,
    DateTime? createdAt,
  }) {
    return ListingEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceInCents: priceInCents ?? this.priceInCents,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      condition: condition ?? this.condition,
      categoryId: categoryId ?? this.categoryId,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavourited: isFavourited ?? this.isFavourited,
      qualityScore: qualityScore ?? this.qualityScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priceInCents,
    sellerId,
    sellerName,
    condition,
    categoryId,
    imageUrls,
    location,
    distanceKm,
    isFavourited,
    qualityScore,
    createdAt,
  ];
}

/// Item condition — matches DB `listing_condition` enum.
///
/// DB values: new_with_tags, new_without_tags, like_new, good, fair, poor
/// Display labels are in `core/l10n/*.json` under `condition.*` keys.
/// Use `'condition.${condition.name}'.tr()` in presentation layer.
enum ListingCondition {
  newWithTags,
  newWithoutTags,
  likeNew,
  good,
  fair,
  poor;

  /// Convert to DB snake_case value.
  String toDb() => switch (this) {
    ListingCondition.newWithTags => 'new_with_tags',
    ListingCondition.newWithoutTags => 'new_without_tags',
    ListingCondition.likeNew => 'like_new',
    ListingCondition.good => 'good',
    ListingCondition.fair => 'fair',
    ListingCondition.poor => 'poor',
  };

  /// Parse from DB snake_case value.
  /// Unknown values default to [good] for forward-compatibility
  /// (e.g., if backend adds a new condition before app update).
  static ListingCondition fromDb(String value) => switch (value) {
    'new_with_tags' => ListingCondition.newWithTags,
    'new_without_tags' => ListingCondition.newWithoutTags,
    'like_new' => ListingCondition.likeNew,
    'good' => ListingCondition.good,
    'fair' => ListingCondition.fair,
    'poor' => ListingCondition.poor,
    _ => ListingCondition.good,
  };
}
