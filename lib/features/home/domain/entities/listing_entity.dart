import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_condition.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_status.dart';

// Re-export enums so existing imports continue to work.
export 'listing_condition.dart';
export 'listing_status.dart';

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
    this.originalPriceInCents,
    this.location,
    this.distanceKm,
    this.isFavourited = false,
    this.qualityScore,
    this.status = ListingStatus.active,
  });

  final String id;
  final String title;
  final String description;

  /// Price in cents (e.g. 4500 = €45.00). Mollie API compatible.
  final int priceInCents;

  /// Original price before discount, in cents. Null when no discount.
  /// Triggers strikethrough display in PriceTag when set.
  final int? originalPriceInCents;

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

  /// Current status of the listing.
  final ListingStatus status;

  final DateTime createdAt;

  ListingEntity copyWith({
    String? id,
    String? title,
    String? description,
    int? priceInCents,
    int? originalPriceInCents,
    String? sellerId,
    String? sellerName,
    ListingCondition? condition,
    String? categoryId,
    List<String>? imageUrls,
    String? location,
    double? distanceKm,
    bool? isFavourited,
    int? qualityScore,
    ListingStatus? status,
    DateTime? createdAt,
  }) {
    return ListingEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceInCents: priceInCents ?? this.priceInCents,
      originalPriceInCents: originalPriceInCents ?? this.originalPriceInCents,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      condition: condition ?? this.condition,
      categoryId: categoryId ?? this.categoryId,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavourited: isFavourited ?? this.isFavourited,
      qualityScore: qualityScore ?? this.qualityScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priceInCents,
    originalPriceInCents,
    sellerId,
    sellerName,
    condition,
    categoryId,
    imageUrls,
    location,
    distanceKm,
    isFavourited,
    qualityScore,
    status,
    createdAt,
  ];
}
