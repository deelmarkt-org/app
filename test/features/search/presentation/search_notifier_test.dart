import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/usecases/toggle_favourite_usecase.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';

class _FailingToggleFavouriteUseCase implements ToggleFavouriteUseCase {
  const _FailingToggleFavouriteUseCase();

  @override
  Future<ListingEntity> call(String listingId) =>
      Future.error(Exception('Network error'));
}

Future<ProviderContainer> _loadedContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      useMockDataProvider.overrideWithValue(true),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  )..listen(searchNotifierProvider, (_, _) {});
  await container.read(searchNotifierProvider.future);
  return container;
}

void main() {
  group('SearchNotifier', () {
    test('build() returns initial state with empty listings', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.listings, isEmpty);
      expect(data.filter.hasQuery, isFalse);
      expect(data.total, 0);
    });

    test('search() populates listings for matching query', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      // Mock data has "Giant Defy Advanced 2 Racefiets" — "race" matches
      await container.read(searchNotifierProvider.notifier).search('race');
      final data = container.read(searchNotifierProvider).requireValue;

      expect(data.listings, isNotEmpty);
      expect(data.filter.query, 'race');
      expect(data.total, greaterThan(0));
    });

    test('search() with empty query does nothing', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('  ');
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.filter.hasQuery, isFalse);
    });

    test('search() returns empty for non-matching query', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container
          .read(searchNotifierProvider.notifier)
          .search('xyznonexistent');
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.listings, isEmpty);
      expect(data.total, 0);
    });

    test('search() adds to recent searches', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('iPhone');
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.recentSearches, contains('iPhone'));
    });

    test('clearRecentSearches() empties list', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('iPhone');
      await container
          .read(searchNotifierProvider.notifier)
          .clearRecentSearches();
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.recentSearches, isEmpty);
    });

    test('search() preserves active filters on new query', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('e');
      await container
          .read(searchNotifierProvider.notifier)
          .updateFilter(
            const SearchFilter(sortOrder: SearchSortOrder.priceLowHigh),
          );

      await container.read(searchNotifierProvider.notifier).search('iPhone');
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.filter.query, 'iPhone');
      expect(data.filter.sortOrder, SearchSortOrder.priceLowHigh);
    });

    test(
      'updateFilter() works without prior query (category browse)',
      () async {
        final container = await _loadedContainer();
        addTearDown(container.dispose);

        await container
            .read(searchNotifierProvider.notifier)
            .updateFilter(const SearchFilter(categoryId: 'cat-sport'));
        final data = container.read(searchNotifierProvider).requireValue;
        expect(data.filter.categoryId, 'cat-sport');
      },
    );

    test('updateFilter() preserves query from current state', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('e');
      final before = container.read(searchNotifierProvider).requireValue;

      await container
          .read(searchNotifierProvider.notifier)
          .updateFilter(
            const SearchFilter(sortOrder: SearchSortOrder.priceLowHigh),
          );
      final after = container.read(searchNotifierProvider).requireValue;

      expect(after.filter.sortOrder, SearchSortOrder.priceLowHigh);
      expect(after.filter.query, before.filter.query);
    });
    test('loadMore() does nothing when no data', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).loadMore();
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.listings, isEmpty);
    });

    test('loadMore() does nothing when not hasMore', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('e');
      final before = container.read(searchNotifierProvider).requireValue;
      // Mock has only 4 items — all returned in first page
      expect(before.hasMore, isFalse);

      await container.read(searchNotifierProvider.notifier).loadMore();
      final after = container.read(searchNotifierProvider).requireValue;
      expect(after.listings.length, before.listings.length);
    });

    test('updateFilter() does nothing without prior search', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container
          .read(searchNotifierProvider.notifier)
          .updateFilter(const SearchFilter(categoryId: 'cat-1'));
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.filter.hasQuery, isFalse);
    });

    test('toggleFavourite() flips isFavourited for matching result', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('e');
      final before = container.read(searchNotifierProvider).requireValue;
      expect(before.listings, isNotEmpty);

      final target = before.listings.first;
      await container
          .read(searchNotifierProvider.notifier)
          .toggleFavourite(target.id);

      final after = container.read(searchNotifierProvider).requireValue;
      final updated = after.listings.firstWhere((l) => l.id == target.id);
      expect(updated.isFavourited, !target.isFavourited);
    });

    test('toggleFavourite() twice returns to original state', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('e');
      final initial = container.read(searchNotifierProvider).requireValue;
      final id = initial.listings.first.id;
      final originalFavourited = initial.listings.first.isFavourited;

      await container.read(searchNotifierProvider.notifier).toggleFavourite(id);
      await container.read(searchNotifierProvider.notifier).toggleFavourite(id);

      final after = container.read(searchNotifierProvider).requireValue;
      final restored = after.listings.firstWhere((l) => l.id == id);
      expect(restored.isFavourited, originalFavourited);
    });

    test(
      'toggleFavourite() reverts only the target listing on failure',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
            toggleFavouriteUseCaseProvider.overrideWith(
              (ref) => const _FailingToggleFavouriteUseCase(),
            ),
          ],
        )..listen(searchNotifierProvider, (_, _) {});
        addTearDown(container.dispose);
        await container.read(searchNotifierProvider.future);

        await container.read(searchNotifierProvider.notifier).search('e');
        final before = container.read(searchNotifierProvider).requireValue;
        expect(before.listings, isNotEmpty);

        final id = before.listings.first.id;
        final originalFav = before.listings.first.isFavourited;

        await container
            .read(searchNotifierProvider.notifier)
            .toggleFavourite(id);

        final after = container.read(searchNotifierProvider).requireValue;
        final reverted = after.listings.firstWhere((l) => l.id == id);
        expect(
          reverted.isFavourited,
          originalFav,
          reason: 'Should revert to original on failure',
        );
        expect(
          after.listings.length,
          before.listings.length,
          reason: 'Should preserve all other listings',
        );
      },
    );

    test('removeRecentSearch() removes specific query', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(searchNotifierProvider.notifier).search('iPhone');
      await container.read(searchNotifierProvider.notifier).search('fiets');
      await container
          .read(searchNotifierProvider.notifier)
          .removeRecentSearch('iPhone');
      final data = container.read(searchNotifierProvider).requireValue;
      expect(data.recentSearches, isNot(contains('iPhone')));
    });
  });

  group('SearchState', () {
    test('equality via Equatable', () {
      const a = SearchState();
      const b = SearchState();
      expect(a, equals(b));
    });

    test('copyWith preserves unchanged fields', () {
      const original = SearchState(total: 42);
      final copy = original.copyWith(hasMore: true);
      expect(copy.total, 42);
      expect(copy.hasMore, isTrue);
    });

    test('copyWith updates all fields', () {
      const original = SearchState();
      final copy = original.copyWith(
        listings: const [],
        filter: const SearchFilter(query: 'x'),
        total: 5,
        hasMore: true,
        isLoadingMore: true,
        recentSearches: const ['a'],
      );
      expect(copy.filter.query, 'x');
      expect(copy.total, 5);
      expect(copy.hasMore, isTrue);
      expect(copy.isLoadingMore, isTrue);
      expect(copy.recentSearches, ['a']);
    });

    test('props includes all fields for Equatable diffing', () {
      const state = SearchState(total: 1, hasMore: true);
      expect(state.props.length, 6);
    });

    test('inequality when total differs', () {
      const a = SearchState(total: 1);
      const b = SearchState(total: 2);
      expect(a, isNot(equals(b)));
    });
  });
}
