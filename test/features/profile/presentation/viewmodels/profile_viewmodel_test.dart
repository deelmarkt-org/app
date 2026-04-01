import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';

/// Creates a container with mock data, subscribes to keep the provider alive,
/// and waits for the initial load to complete.
Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(profileProvider, (_, _) {});
  // User fetched first (200ms), then listings+reviews in parallel (≤500ms).
  await Future<void>.delayed(const Duration(milliseconds: 800));
  return container;
}

void main() {
  group('ProfileNotifier', () {
    test('load() populates user', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileProvider);
      expect(state.user.hasValue, isTrue);
      expect(state.user.requireValue, isNotNull);
    });

    test('load() populates listings', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileProvider);
      expect(state.listings.hasValue, isTrue);
      expect(state.listings.requireValue, isNotEmpty);
    });

    test('load() populates reviews', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileProvider);
      expect(state.reviews.hasValue, isTrue);
      expect(state.reviews.requireValue, isNotEmpty);
    });

    test('initial state is loading for all sections', () async {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      )..listen(profileProvider, (_, _) {});

      final state = container.read(profileProvider);
      expect(state.user.isLoading, isTrue);
      expect(state.listings.isLoading, isTrue);
      expect(state.reviews.isLoading, isTrue);

      // Wait for the background load() to finish before disposing,
      // otherwise the notifier tries to set state after disposal.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      container.dispose();
    });

    test('user entity has expected fields', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final user = container.read(profileProvider).user.requireValue!;
      expect(user.id, isNotEmpty);
      expect(user.displayName, isNotEmpty);
    });
  });

  group('ProfileState', () {
    test('copyWith returns new instance with updated fields', () {
      const state = ProfileState();
      final updated = state.copyWith(user: const AsyncValue.data(null));
      expect(updated.user.hasValue, isTrue);
      expect(updated.listings.isLoading, isTrue);
    });

    test('copyWith preserves existing values when not overridden', () {
      const state = ProfileState(listings: AsyncValue.data([]));
      final updated = state.copyWith(reviews: const AsyncValue.data([]));
      expect(updated.listings.hasValue, isTrue);
      expect(updated.reviews.hasValue, isTrue);
      expect(updated.user.isLoading, isTrue);
    });
  });

  group('reviewRepositoryProvider', () {
    test('returns a ReviewRepository instance', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      final repo = container.read(reviewRepositoryProvider);
      expect(repo, isNotNull);
    });
  });
}
