import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/favourites_notifier.dart';

/// Helper: create a container with mock data, subscribe to keep alive,
/// and wait for initial load.
Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(favouritesNotifierProvider, (_, _) {});
  await container.read(favouritesNotifierProvider.future);
  return container;
}

/// Helper: create a container with pre-populated favourites.
///
/// Overrides [listingRepositoryProvider] with a [MockListingRepository]
/// that already has the given [ids] favourited.
Future<ProviderContainer> _containerWithFavourites(List<String> ids) async {
  final mockRepo = MockListingRepository();
  for (final id in ids) {
    await mockRepo.toggleFavourite(id);
  }
  final container = ProviderContainer(
    overrides: [
      useMockDataProvider.overrideWithValue(true),
      listingRepositoryProvider.overrideWithValue(mockRepo),
    ],
  )..listen(favouritesNotifierProvider, (_, _) {});
  await container.read(favouritesNotifierProvider.future);
  return container;
}

void main() {
  group('FavouritesNotifier', () {
    group('build', () {
      test('returns empty list initially (no favourites in mock)', () async {
        final container = await _loadedContainer();
        addTearDown(container.dispose);

        final state = container.read(favouritesNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.requireValue, isEmpty);
      });

      test('initial state is loading before build completes', () {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);
        container.listen(favouritesNotifierProvider, (_, _) {});

        final state = container.read(favouritesNotifierProvider);
        expect(state.isLoading, isTrue);
      });
    });

    group('with pre-populated favourites', () {
      test('loads favourited listings from repository', () async {
        final container = await _containerWithFavourites([
          'listing-001',
          'listing-003',
        ]);
        addTearDown(container.dispose);

        final listings =
            container.read(favouritesNotifierProvider).requireValue;
        expect(listings, hasLength(2));
        final ids = listings.map((l) => l.id).toSet();
        expect(ids, containsAll(['listing-001', 'listing-003']));
      });
    });

    group('refresh', () {
      test('reloads data successfully', () async {
        final container = await _containerWithFavourites(['listing-001']);
        addTearDown(container.dispose);

        await container.read(favouritesNotifierProvider.notifier).refresh();

        final state = container.read(favouritesNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.requireValue, hasLength(1));
      });
    });

    group('removeFavourite', () {
      test('removes listing from state and returns it', () async {
        final container = await _containerWithFavourites([
          'listing-001',
          'listing-003',
        ]);
        addTearDown(container.dispose);

        final removed = await container
            .read(favouritesNotifierProvider.notifier)
            .removeFavourite('listing-001');

        expect(removed, isNotNull);
        expect(removed!.id, 'listing-001');

        final remaining =
            container.read(favouritesNotifierProvider).requireValue;
        expect(remaining, hasLength(1));
        expect(remaining.first.id, 'listing-003');
      });

      test('returns null when listing not in favourites', () async {
        final container = await _containerWithFavourites(['listing-001']);
        addTearDown(container.dispose);

        final removed = await container
            .read(favouritesNotifierProvider.notifier)
            .removeFavourite('nonexistent-id');

        expect(removed, isNull);
      });

      test('returns null when state has no data', () async {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);
        container.listen(favouritesNotifierProvider, (_, _) {});

        // State is still loading — removeFavourite should return null
        final removed = await container
            .read(favouritesNotifierProvider.notifier)
            .removeFavourite('listing-001');

        expect(removed, isNull);
      });

      test('optimistically removes before API completes', () async {
        final container = await _containerWithFavourites([
          'listing-001',
          'listing-003',
        ]);
        addTearDown(container.dispose);

        // Start remove without awaiting
        final future = container
            .read(favouritesNotifierProvider.notifier)
            .removeFavourite('listing-001');

        // Optimistic update should be immediate
        final optimistic =
            container.read(favouritesNotifierProvider).requireValue;
        expect(optimistic.map((l) => l.id), isNot(contains('listing-001')));

        await future;
      });
    });

    group('undoRemove', () {
      test('re-inserts listing at top of list', () async {
        final container = await _containerWithFavourites([
          'listing-001',
          'listing-003',
        ]);
        addTearDown(container.dispose);

        // Remove first
        final removed = await container
            .read(favouritesNotifierProvider.notifier)
            .removeFavourite('listing-001');

        expect(removed, isNotNull);

        // Undo
        await container
            .read(favouritesNotifierProvider.notifier)
            .undoRemove(removed!);

        final listings =
            container.read(favouritesNotifierProvider).requireValue;
        expect(listings, hasLength(2));
        // Restored listing should be at the top
        expect(listings.first.id, 'listing-001');
      });

      test('does nothing when state has no data', () async {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);
        container.listen(favouritesNotifierProvider, (_, _) {});

        final listing = ListingEntity(
          id: 'listing-001',
          title: 'Test',
          description: 'Test',
          priceInCents: 100,
          sellerId: 'user-001',
          sellerName: 'Test',
          condition: ListingCondition.good,
          categoryId: 'cat-test',
          imageUrls: const [],
          createdAt: DateTime(2026),
        );

        // Should not throw when state is loading
        await container
            .read(favouritesNotifierProvider.notifier)
            .undoRemove(listing);
      });
    });
  });
}
