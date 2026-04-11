import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_condition.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_status.dart';

// Re-export enums so existing imports continue to work.
export 'package:deelmarkt/features/home/domain/entities/listing_condition.dart';
export 'package:deelmarkt/features/home/domain/entities/listing_status.dart';

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
    this.viewCount = 0,
    this.favouriteCount = 0,
  });

  /// Sentinel for [copyWith] — distinguishes "not passed" from "passed as null".
  static const _sentinel = Object();

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

  /// Number of times this listing has been viewed. Defaults to 0.
  final int viewCount;

  /// Number of times this listing has been favourited. Defaults to 0.
  final int favouriteCount;

  final DateTime createdAt;

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields use a sentinel pattern so they can be explicitly
  /// set to `null` (e.g. `copyWith(originalPriceInCents: null)` clears
  /// the discount). Omitting a parameter preserves the current value.
  ListingEntity copyWith({
    String? id,
    String? title,
    String? description,
    int? priceInCents,
    Object? originalPriceInCents = _sentinel,
    String? sellerId,
    String? sellerName,
    ListingCondition? condition,
    String? categoryId,
    List<String>? imageUrls,
    Object? location = _sentinel,
    Object? distanceKm = _sentinel,
    bool? isFavourited,
    Object? qualityScore = _sentinel,
    ListingStatus? status,
    int? viewCount,
    int? favouriteCount,
    DateTime? createdAt,
  }) {
    return ListingEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceInCents: priceInCents ?? this.priceInCents,
      originalPriceInCents:
          _ifSentinel(originalPriceInCents, this.originalPriceInCents) as int?,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      condition: condition ?? this.condition,
      categoryId: categoryId ?? this.categoryId,
      imageUrls: imageUrls ?? this.imageUrls,
      location: _ifSentinel(location, this.location) as String?,
      distanceKm: _ifSentinel(distanceKm, this.distanceKm) as double?,
      isFavourited: isFavourited ?? this.isFavourited,
      qualityScore: _ifSentinel(qualityScore, this.qualityScore) as int?,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      favouriteCount: favouriteCount ?? this.favouriteCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Resolves a sentinel-guarded nullable field for [copyWith].
  static dynamic _ifSentinel(dynamic value, dynamic current) {
    if (value == _sentinel) return current;
    return value;
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
    viewCount,
    favouriteCount,
    createdAt,
  ];
}
