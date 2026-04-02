import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';

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
  });
}
