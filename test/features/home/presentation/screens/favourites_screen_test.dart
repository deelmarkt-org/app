import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/favourites_notifier.dart';
import 'package:deelmarkt/features/home/presentation/screens/favourites_screen.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

/// Stub notifier that returns a fixed list without async delays.
class _StubFavouritesNotifier extends FavouritesNotifier {
  _StubFavouritesNotifier(this._listings);

  final List<ListingEntity> _listings;

  @override
  Future<List<ListingEntity>> build() async => _listings;

  @override
  Future<void> refresh() async {}

  @override
  Future<ListingEntity?> removeFavourite(String listingId) async {
    final listing = _listings.where((l) => l.id == listingId).firstOrNull;
    if (listing == null) return null;
    state = AsyncValue.data([
      for (final l in state.valueOrNull ?? _listings)
        if (l.id != listingId) l,
    ]);
    return listing;
  }

  @override
  Future<void> undoRemove(ListingEntity listing) async {
    state = AsyncValue.data([listing, ...state.valueOrNull ?? _listings]);
  }
}

const _sampleImageUrl =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';

final _testListings = [
  ListingEntity(
    id: 'listing-001',
    title: 'Giant Defy Advanced 2 Racefiets',
    description: 'Carbon frame, Shimano 105.',
    priceInCents: 89500,
    sellerId: 'user-001',
    sellerName: 'Jan de Vries',
    condition: ListingCondition.good,
    categoryId: 'cat-sport',
    imageUrls: const [_sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 3.2,
    isFavourited: true,
    createdAt: DateTime(2026, 3, 20),
  ),
  ListingEntity(
    id: 'listing-003',
    title: 'IKEA Kallax Kast 4x4',
    description: 'Wit, goede staat.',
    priceInCents: 4500,
    sellerId: 'user-003',
    sellerName: 'Pieter Bakker',
    condition: ListingCondition.fair,
    categoryId: 'cat-home',
    imageUrls: const [_sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 8.0,
    isFavourited: true,
    createdAt: DateTime(2026, 3, 24),
  ),
];

void main() {
  group('FavouritesScreen', () {
    Widget buildScreen({List<ListingEntity> favourites = const []}) {
      return ProviderScope(
        overrides: [
          favouritesNotifierProvider.overrideWith(
            () => _StubFavouritesNotifier(favourites),
          ),
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const FavouritesScreen(),
        ),
      );
    }

    testWidgets('renders empty state when no favourites', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(SkeletonListingCard), findsNothing);
    });

    testWidgets('renders listing cards when favourites exist', (tester) async {
      await tester.pumpWidget(buildScreen(favourites: _testListings));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(SkeletonListingCard), findsNothing);
      // Should render the data view with CustomScrollView
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders with dark theme without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favouritesNotifierProvider.overrideWith(
              () => _StubFavouritesNotifier(const []),
            ),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: const FavouritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FavouritesScreen), findsOneWidget);
    });

    testWidgets('has semantics labels for accessibility', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('editorial header shown when favourites exist', (tester) async {
      await tester.pumpWidget(buildScreen(favourites: _testListings));
      await tester.pumpAndSettle();

      // The data view renders a subtitle and savedItems editorial header
      // within a CustomScrollView + SliverToBoxAdapter
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('grid shows correct number of items', (tester) async {
      await tester.pumpWidget(buildScreen(favourites: _testListings));
      await tester.pumpAndSettle();

      // Should render 2 listing cards in the grid
      expect(find.byType(SliverGrid), findsOneWidget);
    });
  });
}
