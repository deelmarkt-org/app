import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/category_browse_notifier.dart';

/// Helper: create a container with mock data, subscribe to keep alive,
/// and wait for initial load.
Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(categoryBrowseNotifierProvider, (_, _) {});

  await container.read(categoryBrowseNotifierProvider.future);
  return container;
}

void main() {
  group('CategoryBrowseNotifier', () {
    test('build() loads 8 L1 categories', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final categories =
          container.read(categoryBrowseNotifierProvider).requireValue;
      expect(categories, hasLength(8));
    });

    test('all categories are top-level', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final categories =
          container.read(categoryBrowseNotifierProvider).requireValue;
      for (final category in categories) {
        expect(category.isTopLevel, isTrue);
      }
    });

    test('initial state is loading', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(categoryBrowseNotifierProvider, (_, _) {});

      final state = container.read(categoryBrowseNotifierProvider);
      expect(state.isLoading, isTrue);
    });

    test('refresh() reloads data', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(categoryBrowseNotifierProvider.notifier).refresh();

      final state = container.read(categoryBrowseNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue, hasLength(8));
    });
  });
}
