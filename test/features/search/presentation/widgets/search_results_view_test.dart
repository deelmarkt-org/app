import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_view.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

final _testListing = ListingEntity(
  id: 'test-1',
  title: 'Test Item',
  description: 'A test listing.',
  priceInCents: 4500,
  sellerId: 'user-1',
  sellerName: 'Jan',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  void setCompact(WidgetTester tester) {
    // 800px is below the 840 expanded breakpoint but wide enough for the
    // horizontal chip bar to materialise 3+ chips (viewport-clipping).
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
  }

  void setExpanded(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget buildView({
    required SearchState data,
    ThemeData? theme,
    ValueChanged<SearchFilter>? onFilterApply,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          // GH-59: EscrowAwareListingCard reads the Unleash flag — override
          // it here so widget tests don't try to contact the real SDK.
          isFeatureEnabledProvider(
            FeatureFlags.listingsEscrowBadge,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: Scaffold(
            body: SearchResultsView(
              data: data,
              onListingTap: (_) {},
              onFavouriteTap: (_) {},
              onLoadMore: () {},
              onFilterTap: () {},
              onFilterApply: onFilterApply ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('SearchResultsView — compact (<840)', () {
    testWidgets('shows empty state when no listings', (tester) async {
      setCompact(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(data: const SearchState(filter: SearchFilter(query: 'xyz'))),
      );
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(FilterPanel), findsNothing);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('shows results count and grid', (tester) async {
      setCompact(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: const SearchFilter(query: 'test'),
            total: 1,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(FilterPanel), findsNothing);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('shows filter chips row', (tester) async {
      setCompact(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: const SearchFilter(query: 'test', categoryId: 'cat-1'),
            total: 1,
          ),
        ),
      );
      await tester.pump();
      // Filter chips rendered in horizontal scroll (viewport may clip some).
      expect(find.byType(ActionChip), findsAtLeast(3));
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('shows loading indicator when isLoadingMore', (tester) async {
      setCompact(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: const SearchFilter(query: 'test'),
            total: 10,
            hasMore: true,
            isLoadingMore: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('renders with dark theme', (tester) async {
      setCompact(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: const SearchFilter(query: 'test'),
            total: 1,
          ),
          theme: DeelmarktTheme.dark,
        ),
      );
      await tester.pump();
      expect(find.byType(SearchResultsView), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
    });
  });

  group('SearchResultsView — expanded (≥840) sidebar (#193 PR C)', () {
    // Pre-populate a non-null `maxDistanceKm` so the distance slider's
    // right-side Text renders the short "{n} km" label instead of the
    // l10n key `search.filter.anyDistance` (which only resolves to the
    // short "Any distance" / "Elke afstand" at runtime — in the unit
    // test env it falls back to the raw key and overflows the 240-px
    // sidebar's inner width). This keeps the test focused on layout.
    const sidebarSafeFilter = SearchFilter(query: 'test', maxDistanceKm: 50);

    testWidgets('shows filter sidebar + vertical divider', (tester) async {
      setExpanded(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: sidebarSafeFilter,
            total: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilterPanel), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
      // Compact chip bar NOT rendered on expanded.
      expect(find.byType(ActionChip), findsNothing);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('sidebar uses FilterPanelVariant.sidebar (live-apply)', (
      tester,
    ) async {
      setExpanded(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(
          data: SearchState(
            listings: [_testListing],
            filter: sidebarSafeFilter,
            total: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panel = tester.widget<FilterPanel>(find.byType(FilterPanel));
      expect(panel.variant, FilterPanelVariant.sidebar);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('empty-state shows in right pane while sidebar stays visible', (
      tester,
    ) async {
      setExpanded(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildView(data: const SearchState(filter: sidebarSafeFilter)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(FilterPanel), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
    });
  });
}
