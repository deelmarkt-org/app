import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_favourites_mixin.dart';
import 'package:deelmarkt/features/search/presentation/search_providers.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';

part 'search_notifier.g.dart';

@riverpod
class SearchNotifier extends _$SearchNotifier with SearchFavouritesMixin {
  static const _logTag = 'search';

  @override
  Future<SearchState> build() async {
    final recents = await ref.watch(recentSearchesRepositoryProvider).getAll();
    return SearchState(recentSearches: recents);
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Preserve active filters when user types a new query
    final current = state.valueOrNull;
    final filter =
        current != null && current.filter.hasActiveFilters
            ? current.filter.copyWith(query: trimmed)
            : SearchFilter(query: trimmed);
    state = const AsyncValue.loading();

    // GH #221 — search_query trace covers the post-debounce committed
    // query, NOT per-keystroke (debounce happens upstream of this method).
    // Stops in finally so failures still close the span.
    final tracer = ref.read(performanceTracerProvider);
    final handle = tracer.start(TraceNames.searchQuery);

    try {
      final useCase = ref.read(searchListingsUseCaseProvider);
      final result = await useCase(filter);
      final recentsRepo = ref.read(recentSearchesRepositoryProvider);
      await recentsRepo.add(trimmed);
      final recents = await recentsRepo.getAll();

      state = AsyncValue.data(
        SearchState(
          listings: result.listings,
          filter: filter,
          total: result.total,
          hasMore: result.hasMore,
          recentSearches: recents,
        ),
      );
    } on Exception catch (e, st) {
      AppLogger.error('Search failed', error: e, tag: _logTag);
      state = AsyncValue.error(e, st);
    } finally {
      await handle.stop();
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(searchListingsUseCaseProvider);
      final offset = current.listings.length;
      final result = await useCase(current.filter, offset: offset);

      state = AsyncValue.data(
        current.copyWith(
          listings: [...current.listings, ...result.listings],
          total: result.total,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (e) {
      AppLogger.error('Load more failed', error: e, tag: _logTag);
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> updateFilter(SearchFilter filter) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Preserve current query if the new filter doesn't specify one
    final query = filter.query.isNotEmpty ? filter.query : current.filter.query;
    final updated = filter.copyWith(query: query);
    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(searchListingsUseCaseProvider);
      final result = await useCase(updated);

      state = AsyncValue.data(
        current.copyWith(
          listings: result.listings,
          filter: updated,
          total: result.total,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (e, st) {
      AppLogger.error('Filter update failed', error: e, tag: _logTag);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeRecentSearch(String query) async {
    final recentsRepo = ref.read(recentSearchesRepositoryProvider);
    await recentsRepo.remove(query);
    final recents = await recentsRepo.getAll();
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(recentSearches: recents));
    }
  }

  Future<void> clearRecentSearches() async {
    final recentsRepo = ref.read(recentSearchesRepositoryProvider);
    await recentsRepo.clear();
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(recentSearches: const []));
    }
  }
}
