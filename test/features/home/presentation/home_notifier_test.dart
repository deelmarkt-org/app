import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';

/// Helper: create a container with mock data, subscribe to keep alive,
/// and wait for initial load.
Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer(
      overrides: [useMockDataProvider.overrideWithValue(true)],
    )
    // Keep the provider alive by subscribing
    ..listen(homeNotifierProvider, (_, _) {});
  // Mock repos use Future.delayed (200-300ms) — wait for build to complete.
  await container.read(homeNotifierProvider.future);
  return container;
}

void main() {
  group('HomeNotifier', () {
    test('build() loads categories, nearby, and recent listings', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final data = container.read(homeNotifierProvider).requireValue;
      expect(data.categories, isNotEmpty);
      expect(data.nearby, isNotEmpty);
      expect(data.recent, isNotEmpty);
    });

    test('initial state is loading', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(homeNotifierProvider, (_, _) {});

      final state = container.read(homeNotifierProvider);
      expect(state.isLoading, isTrue);
    });

    test('refresh() reloads data', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(homeNotifierProvider.notifier).refresh();

      final state = container.read(homeNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.categories, isNotEmpty);
    });

    test('toggleFavourite() optimistically updates nearby listing', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final data = container.read(homeNotifierProvider).requireValue;
      final firstListing = data.nearby.first;
      final wasFavourited = firstListing.isFavourited;

      // Start toggle — check optimistic update before API completes
      final future = container
          .read(homeNotifierProvider.notifier)
          .toggleFavourite(firstListing.id);

      // Optimistic update should be immediate
      final optimistic = container.read(homeNotifierProvider).requireValue;
      final updated = optimistic.nearby.firstWhere(
        (l) => l.id == firstListing.id,
      );
      expect(updated.isFavourited, isNot(wasFavourited));

      await future;
    });

    test('toggleFavourite() with no data does nothing', () async {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(homeNotifierProvider, (_, _) {});

      // State is still loading — should not throw
      await container
          .read(homeNotifierProvider.notifier)
          .toggleFavourite('nonexistent');
    });
  });

  group('HomeState', () {
    test('default state has empty lists', () {
      const state = HomeState();
      expect(state.categories, isEmpty);
      expect(state.nearby, isEmpty);
      expect(state.recent, isEmpty);
    });

    test('equality via Equatable', () {
      const a = HomeState();
      const b = HomeState();
      expect(a, equals(b));
    });
  });
}
