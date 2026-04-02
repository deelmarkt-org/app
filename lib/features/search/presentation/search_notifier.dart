import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/data/shared_prefs_recent_searches_repo.dart';
import 'package:deelmarkt/features/search/domain/recent_searches_repository.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/domain/search_listings_usecase.dart';

part 'search_notifier.g.dart';

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

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>(
  (ref) => SharedPrefsRecentSearchesRepo(ref.watch(sharedPreferencesProvider)),
);

final searchListingsUseCaseProvider = Provider<SearchListingsUseCase>(
  (ref) => SearchListingsUseCase(ref.watch(listingRepositoryProvider)),
);

@riverpod
class SearchNotifier extends _$SearchNotifier {
  static const _logTag = 'search';
  @override
  Future<SearchState> build() async {
    final recents = await ref.watch(recentSearchesRepositoryProvider).getAll();
    return SearchState(recentSearches: recents);
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final filter = SearchFilter(query: trimmed);
    state = const AsyncValue.loading();

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
    if (current == null || !current.filter.hasQuery) return;

    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(searchListingsUseCaseProvider);
      final result = await useCase(filter);

      state = AsyncValue.data(
        current.copyWith(
          listings: result.listings,
          filter: filter,
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
