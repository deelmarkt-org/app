import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_expanded_view.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    // Render at the expanded breakpoint so the sidebar materialises.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  ListingEntity makeListing() {
    return ListingEntity(
      id: 'l1',
      title: 'Bike',
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

  Widget host({
    required SearchState data,
    ValueChanged<SearchFilter>? onFilterApply,
  }) {
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
        child: MaterialApp(
          home: Scaffold(
            body: SearchResultsExpandedView(
              data: data,
              onListingTap: (_) {},
              onFavouriteTap: (_) {},
              onLoadMore: () {},
              onFilterApply: onFilterApply ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  void setExpanded(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Pre-populate `maxDistanceKm` so the distance slider renders the short
  // "{n} km" label instead of the unresolved l10n key that overflows the
  // 240-px sidebar width in the test env. Same workaround as
  // search_results_view_test.dart (#193 PR C).
  const sidebarSafeFilter = SearchFilter(query: 'bike', maxDistanceKm: 50);

  testWidgets('renders the FilterPanel sidebar even when results are empty', (
    tester,
  ) async {
    setExpanded(tester);
    await tester.pumpWidget(
      host(data: const SearchState(filter: sidebarSafeFilter)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FilterPanel), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    // Drain pending mock-data timers so the framework doesn't fail with
    // "A Timer is still pending" on dispose.
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('renders sidebar + scroll view when listings has rows', (
    tester,
  ) async {
    setExpanded(tester);
    final state = SearchState(
      filter: sidebarSafeFilter,
      listings: [makeListing()],
      total: 1,
    );
    await tester.pumpWidget(host(data: state));
    await tester.pumpAndSettle();
    expect(find.byType(FilterPanel), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });
}
