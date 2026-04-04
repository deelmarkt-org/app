import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/screens/category_detail_screen.dart';
import 'package:deelmarkt/features/home/presentation/widgets/subcategory_chip.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Stub notifier that returns a pre-built state without async delays.
class _StubCategoryDetailNotifier extends CategoryDetailNotifier {
  _StubCategoryDetailNotifier(this._result);

  final CategoryDetailState _result;

  @override
  Future<CategoryDetailState> build(String arg) async => _result;

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

/// Loading notifier that never completes — keeps state in loading forever.
class _LoadingCategoryDetailNotifier extends CategoryDetailNotifier {
  @override
  Future<CategoryDetailState> build(String arg) {
    return Completer<CategoryDetailState>().future;
  }

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

/// Error notifier that always throws.
class _ErrorCategoryDetailNotifier extends CategoryDetailNotifier {
  @override
  Future<CategoryDetailState> build(String arg) async {
    throw Exception('Network error');
  }

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

const _sampleImageUrl =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';

const _parentCategory = CategoryEntity(
  id: 'cat-electronics',
  name: 'Elektronica',
  icon: 'device-mobile',
  listingCount: 42,
);

final _subcategories = [
  const CategoryEntity(
    id: 'cat-phones',
    name: 'Telefoons',
    icon: 'device-mobile',
    parentId: 'cat-electronics',
    listingCount: 15,
  ),
  const CategoryEntity(
    id: 'cat-laptops',
    name: 'Laptops',
    icon: 'laptop',
    parentId: 'cat-electronics',
    listingCount: 12,
  ),
  const CategoryEntity(
    id: 'cat-tablets',
    name: 'Tablets',
    icon: 'device-tablet',
    parentId: 'cat-electronics',
    listingCount: 8,
  ),
];

final _featuredListings = [
  ListingEntity(
    id: 'listing-001',
    title: 'iPhone 15 Pro',
    description: 'Excellent condition',
    priceInCents: 89500,
    sellerId: 'user-001',
    sellerName: 'Jan de Vries',
    condition: ListingCondition.good,
    categoryId: 'cat-electronics',
    imageUrls: const [_sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 3.2,
    createdAt: DateTime(2026, 3, 20),
  ),
  ListingEntity(
    id: 'listing-002',
    title: 'MacBook Air M3',
    description: 'Barely used',
    priceInCents: 115000,
    sellerId: 'user-002',
    sellerName: 'Pieter Bakker',
    condition: ListingCondition.likeNew,
    categoryId: 'cat-electronics',
    imageUrls: const [_sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 8.0,
    isFavourited: true,
    createdAt: DateTime(2026, 3, 24),
  ),
];

final _fullState = CategoryDetailState(
  parent: _parentCategory,
  subcategories: _subcategories,
  featuredListings: _featuredListings,
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget buildScreen({required CategoryDetailState state, ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          categoryDetailNotifierProvider.overrideWith(
            () => _StubCategoryDetailNotifier(state),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: const CategoryDetailScreen(categoryId: 'cat-electronics'),
        ),
      ),
    );
  }

  Widget buildLoadingScreen() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          categoryDetailNotifierProvider.overrideWith(
            () => _LoadingCategoryDetailNotifier(),
          ),
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const CategoryDetailScreen(categoryId: 'cat-electronics'),
        ),
      ),
    );
  }

  Widget buildErrorScreen() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          categoryDetailNotifierProvider.overrideWith(
            () => _ErrorCategoryDetailNotifier(),
          ),
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const CategoryDetailScreen(categoryId: 'cat-electronics'),
        ),
      ),
    );
  }

  group('CategoryDetailScreen', () {
    testWidgets('shows loading skeleton initially', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoadingScreen());
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('shows error state with retry button', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildErrorScreen());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows parent name in AppBar when data loaded', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(state: _fullState));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Elektronica'), findsOneWidget);
    });

    testWidgets('renders subcategory chips section', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(state: _fullState));
      await tester.pumpAndSettle();

      expect(find.byType(SubcategoryChip), findsNWidgets(3));
      expect(find.text('Telefoons'), findsOneWidget);
      expect(find.text('Laptops'), findsOneWidget);
      expect(find.text('Tablets'), findsOneWidget);
    });

    testWidgets('renders featured listings grid', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(state: _fullState));
      await tester.pumpAndSettle();

      expect(find.byType(DeelCard), findsNWidgets(2));
      expect(find.byType(SliverGrid), findsOneWidget);
    });

    testWidgets('shows empty message when no subcategories and no listings', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const emptyState = CategoryDetailState(parent: _parentCategory);
      await tester.pumpWidget(buildScreen(state: emptyState));
      await tester.pumpAndSettle();

      expect(find.byType(SubcategoryChip), findsNothing);
      expect(find.byType(DeelCard), findsNothing);
      expect(find.byType(SliverFillRemaining), findsOneWidget);
    });

    testWidgets('renders with dark theme without error', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(state: _fullState, theme: DeelmarktTheme.dark),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CategoryDetailScreen), findsOneWidget);
      expect(find.text('Elektronica'), findsOneWidget);
    });

    testWidgets('shows only subcategories when no featured listings', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final subcatsOnly = CategoryDetailState(
        parent: _parentCategory,
        subcategories: _subcategories,
      );
      await tester.pumpWidget(buildScreen(state: subcatsOnly));
      await tester.pumpAndSettle();

      expect(find.byType(SubcategoryChip), findsNWidgets(3));
      expect(find.byType(DeelCard), findsNothing);
      expect(find.byType(SliverFillRemaining), findsNothing);
    });

    testWidgets('shows only featured listings when no subcategories', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final listingsOnly = CategoryDetailState(
        parent: _parentCategory,
        featuredListings: _featuredListings,
      );
      await tester.pumpWidget(buildScreen(state: listingsOnly));
      await tester.pumpAndSettle();

      expect(find.byType(SubcategoryChip), findsNothing);
      expect(find.byType(DeelCard), findsNWidgets(2));
      expect(find.byType(SliverGrid), findsOneWidget);
    });

    testWidgets('uses CustomScrollView for data view', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(state: _fullState));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
