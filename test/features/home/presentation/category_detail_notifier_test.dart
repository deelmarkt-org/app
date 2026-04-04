import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';

/// Minimal category for state tests.
const _testCategory = CategoryEntity(id: 'test-id', name: 'Test', icon: 'car');

/// Helper: create a container with mock data, subscribe to a category detail
/// provider, and wait for initial load.
Future<ProviderContainer> _loadedContainer(String categoryId) async {
  final provider = categoryDetailNotifierProvider(categoryId);
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(provider, (_, _) {});

  await container.read(provider.future);
  return container;
}

void main() {
  group('CategoryDetailNotifier', () {
    test(
      'build with valid L1 ID loads parent, subcategories, and listings',
      () async {
        final container = await _loadedContainer('cat-electronics');
        addTearDown(container.dispose);

        final state =
            container
                .read(categoryDetailNotifierProvider('cat-electronics'))
                .requireValue;

        expect(state.parent.id, 'cat-electronics');
        expect(state.parent.name, 'Elektronica');
        expect(state.subcategories, hasLength(3));
        expect(
          state.subcategories.map((c) => c.id),
          containsAll(['cat-phones', 'cat-laptops', 'cat-gaming']),
        );
        expect(state.featuredListings, isNotEmpty);
      },
    );

    test('build with unknown ID throws', () async {
      final provider = categoryDetailNotifierProvider('cat-nonexistent');
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      )..listen(provider, (_, _) {});
      addTearDown(container.dispose);

      try {
        await container.read(provider.future);
        fail('Expected an exception for unknown category ID');
      } on Exception catch (e) {
        expect(e.toString(), contains('Category not found'));
      }
    });

    test('toggleFavourite updates listing state optimistically', () async {
      final container = await _loadedContainer('cat-electronics');
      addTearDown(container.dispose);

      final provider = categoryDetailNotifierProvider('cat-electronics');
      final state = container.read(provider).requireValue;

      // Skip if no featured listings
      if (state.featuredListings.isEmpty) return;

      final firstListing = state.featuredListings.first;
      final wasFavourited = firstListing.isFavourited;

      // Start toggle -- check optimistic update before API completes
      final future = container
          .read(provider.notifier)
          .toggleFavourite(firstListing.id);

      // Optimistic update should be immediate
      final optimistic = container.read(provider).requireValue;
      final updated = optimistic.featuredListings.firstWhere(
        (l) => l.id == firstListing.id,
      );
      expect(updated.isFavourited, isNot(wasFavourited));

      await future;
    });

    test('toggleFavourite with no data does nothing', () async {
      final provider = categoryDetailNotifierProvider('cat-electronics');
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});

      // State is still loading -- should not throw
      await container.read(provider.notifier).toggleFavourite('nonexistent');
    });
  });

  group('CategoryDetailState', () {
    test('equality via Equatable', () {
      const a = CategoryDetailState(parent: _testCategory);
      const b = CategoryDetailState(parent: _testCategory);
      expect(a, equals(b));
    });

    test('copyWith replaces fields', () {
      const state = CategoryDetailState(parent: _testCategory);
      final updated = state.copyWith(subcategories: [_testCategory]);
      expect(updated.subcategories, hasLength(1));
      expect(updated.parent, _testCategory);
    });
  });
}
