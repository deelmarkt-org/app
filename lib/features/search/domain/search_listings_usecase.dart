import 'package:deelmarkt/core/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Executes a filtered search against the listing repository.
class SearchListingsUseCase {
  const SearchListingsUseCase(this._repository);

  final ListingRepository _repository;

  Future<ListingSearchResult> call(
    SearchFilter filter, {
    int offset = 0,
    int limit = 20,
  }) {
    final sortBy = switch (filter.sortOrder) {
      SearchSortOrder.priceLowHigh => 'price_cents',
      SearchSortOrder.priceHighLow => 'price_cents',
      SearchSortOrder.newest => 'created_at',
      // Distance sort not yet supported by backend — fall back to relevance
      SearchSortOrder.nearest => null,
      SearchSortOrder.relevance => null,
    };
    final ascending = filter.sortOrder == SearchSortOrder.priceLowHigh;

    return _repository.search(
      query: filter.query,
      categoryId: filter.categoryId,
      minPriceCents: filter.minPriceCents,
      maxPriceCents: filter.maxPriceCents,
      condition: filter.condition,
      sortBy: sortBy,
      ascending: ascending,
      offset: offset,
      limit: limit,
    );
  }
}
