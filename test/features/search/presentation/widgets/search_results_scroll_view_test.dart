import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_scroll_view.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          isFeatureEnabledProvider(
            FeatureFlags.listingsEscrowBadge,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  ListingEntity makeListing(String id) {
    return ListingEntity(
      id: id,
      title: 'Item $id',
      description: '',
      priceInCents: 100,
      sellerId: 'u',
      sellerName: 'Jan',
      condition: ListingCondition.good,
      categoryId: 'c1',
      imageUrls: const [],
      createdAt: DateTime(2026),
    );
  }

  testWidgets('renders a CustomScrollView with the supplied header sliver', (
    tester,
  ) async {
    const headerKey = Key('test-header');
    await tester.pumpWidget(
      host(
        SearchResultsScrollView(
          headerSliver: const SliverToBoxAdapter(
            key: headerKey,
            child: Text('header'),
          ),
          listings: [makeListing('l1')],
          isLoadingMore: false,
          hasMore: true,
          onListingTap: (_) {},
          onFavouriteTap: (_) {},
          onLoadMore: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byKey(headerKey), findsOneWidget);
    expect(find.byType(AdaptiveListingGrid), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a load-more spinner only when isLoadingMore=true', (
    tester,
  ) async {
    Widget build({required bool loading}) {
      return host(
        SearchResultsScrollView(
          headerSliver: const SliverToBoxAdapter(child: Text('h')),
          listings: [makeListing('l1')],
          isLoadingMore: loading,
          hasMore: true,
          onListingTap: (_) {},
          onFavouriteTap: (_) {},
          onLoadMore: () {},
        ),
      );
    }

    await tester.pumpWidget(build(loading: true));
    // Spinner animates indefinitely, so pumpAndSettle never returns —
    // a single pump is enough to materialise the sliver.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(build(loading: false));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('guards onLoadMore: skips the call when isLoadingMore=true', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        SearchResultsScrollView(
          headerSliver: const SliverToBoxAdapter(child: Text('h')),
          listings: List.generate(40, (i) => makeListing('l$i')),
          isLoadingMore: true,
          hasMore: true,
          onListingTap: (_) {},
          onFavouriteTap: (_) {},
          onLoadMore: () => calls++,
        ),
      ),
    );
    await tester.pump();
    // Drag past the threshold; with isLoadingMore=true the guard short-
    // circuits onLoadMore and `calls` stays at 0.
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -2000),
      4000,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 0);
  });

  testWidgets('guards onLoadMore: skips the call when hasMore=false', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        SearchResultsScrollView(
          headerSliver: const SliverToBoxAdapter(child: Text('h')),
          listings: List.generate(40, (i) => makeListing('l$i')),
          isLoadingMore: false,
          hasMore: false,
          onListingTap: (_) {},
          onFavouriteTap: (_) {},
          onLoadMore: () => calls++,
        ),
      ),
    );
    await tester.pump();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -2000),
      4000,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 0);
  });
}
