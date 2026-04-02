import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Immutable state for the search screen.
class SearchState extends Equatable {
  const SearchState({
    this.listings = const [],
    this.filter = SearchFilter.empty,
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.recentSearches = const [],
  });

  final List<ListingEntity> listings;
  final SearchFilter filter;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final List<String> recentSearches;

  SearchState copyWith({
    List<ListingEntity>? listings,
    SearchFilter? filter,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    List<String>? recentSearches,
  }) {
    return SearchState(
      listings: listings ?? this.listings,
      filter: filter ?? this.filter,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [
    listings,
    filter,
    total,
    hasMore,
    isLoadingMore,
    recentSearches,
  ];
}
