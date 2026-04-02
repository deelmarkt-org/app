import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';

/// The mock listing repo uses IDs 'listing-1' to 'listing-4'.
const _testListingId = 'listing-001';

Future<ProviderContainer> _loadedContainer(String listingId) async {
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(listingDetailNotifierProvider(listingId), (_, _) {});
  await container.read(listingDetailNotifierProvider(listingId).future);
  return container;
}

void main() {
  group('ListingDetailNotifier', () {
    test('build() loads listing and seller', () async {
      final container = await _loadedContainer(_testListingId);
      addTearDown(container.dispose);

      final data =
          container
              .read(listingDetailNotifierProvider(_testListingId))
              .requireValue;
      expect(data.listing.id, _testListingId);
      expect(data.listing.title, isNotEmpty);
      expect(data.seller, isNotNull);
    });

    test('initial state is loading', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(
        listingDetailNotifierProvider(_testListingId),
        (_, _) {},
      );

      final state = container.read(
        listingDetailNotifierProvider(_testListingId),
      );
      expect(state.isLoading, isTrue);
    });

    test('returns error for nonexistent listing', () async {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      )..listen(listingDetailNotifierProvider('nonexistent'), (_, _) {});

      // Wait for the future to complete (it will error).
      try {
        await container.read(
          listingDetailNotifierProvider('nonexistent').future,
        );
      } on Exception catch (_) {
        // Expected
      }

      final state = container.read(
        listingDetailNotifierProvider('nonexistent'),
      );
      expect(state.hasError, isTrue);
    });

    test('toggleFavourite() optimistically flips state', () async {
      final container = await _loadedContainer(_testListingId);
      addTearDown(container.dispose);

      final before =
          container
              .read(listingDetailNotifierProvider(_testListingId))
              .requireValue;
      final wasFav = before.listing.isFavourited;

      final future =
          container
              .read(listingDetailNotifierProvider(_testListingId).notifier)
              .toggleFavourite();

      // Optimistic: should flip immediately
      final optimistic =
          container
              .read(listingDetailNotifierProvider(_testListingId))
              .requireValue;
      expect(optimistic.listing.isFavourited, isNot(wasFav));

      await future;
    });

    test('toggleFavourite() with no data does nothing', () async {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      container.listen(
        listingDetailNotifierProvider(_testListingId),
        (_, _) {},
      );

      // State is still loading — should not throw
      await container
          .read(listingDetailNotifierProvider(_testListingId).notifier)
          .toggleFavourite();
    });
  });

  group('ListingDetailState', () {
    test('equality via Equatable', () {
      final a = ListingDetailState(listing: _dummyListing());
      final b = ListingDetailState(listing: _dummyListing());
      expect(a, equals(b));
    });

    test('props include listing, seller, category, and isOwnListing', () {
      final state = ListingDetailState(listing: _dummyListing());
      expect(state.props.length, 4);
    });
  });
}

/// Minimal listing for Equatable tests.
ListingEntity _dummyListing() {
  return ListingEntity(
    id: 'test',
    title: 'Test',
    description: 'A test listing',
    priceInCents: 1000,
    sellerId: 'seller-1',
    sellerName: 'Test Seller',
    condition: ListingCondition.good,
    categoryId: 'cat-1',
    imageUrls: const [],
    createdAt: DateTime(2026),
  );
}
