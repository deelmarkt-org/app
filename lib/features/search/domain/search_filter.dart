import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

/// Sort order options for search results.
enum SearchSortOrder { relevance, priceLowHigh, priceHighLow, newest, nearest }

/// Immutable filter state for listing search — pure Dart domain model.
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query = '',
    this.categoryId,
    this.minPriceCents,
    this.maxPriceCents,
    this.condition,
    this.maxDistanceKm,
    this.sortOrder = SearchSortOrder.relevance,
  });

  static const empty = SearchFilter();

  final String query;
  final String? categoryId;
  final int? minPriceCents;
  final int? maxPriceCents;
  final ListingCondition? condition;
  final double? maxDistanceKm;
  final SearchSortOrder sortOrder;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasActiveFilters =>
      categoryId != null ||
      minPriceCents != null ||
      maxPriceCents != null ||
      condition != null ||
      maxDistanceKm != null ||
      sortOrder != SearchSortOrder.relevance;

  int get activeFilterCount {
    var count = 0;
    if (categoryId != null) count++;
    if (minPriceCents != null || maxPriceCents != null) count++;
    if (condition != null) count++;
    if (maxDistanceKm != null) count++;
    if (sortOrder != SearchSortOrder.relevance) count++;
    return count;
  }

  SearchFilter copyWith({
    String? query,
    String? Function()? categoryId,
    int? Function()? minPriceCents,
    int? Function()? maxPriceCents,
    ListingCondition? Function()? condition,
    double? Function()? maxDistanceKm,
    SearchSortOrder? sortOrder,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      minPriceCents:
          minPriceCents != null ? minPriceCents() : this.minPriceCents,
      maxPriceCents:
          maxPriceCents != null ? maxPriceCents() : this.maxPriceCents,
      condition: condition != null ? condition() : this.condition,
      maxDistanceKm:
          maxDistanceKm != null ? maxDistanceKm() : this.maxDistanceKm,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    query,
    categoryId,
    minPriceCents,
    maxPriceCents,
    condition,
    maxDistanceKm,
    sortOrder,
  ];
}
