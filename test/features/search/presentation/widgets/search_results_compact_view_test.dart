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
import 'package:deelmarkt/features/search/presentation/widgets/search_results_compact_view.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
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

  Widget host({required SearchState data, VoidCallback? onFilterTap}) {
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
            body: SearchResultsCompactView(
              data: data,
              onListingTap: (_) {},
              onFavouriteTap: (_) {},
              onLoadMore: () {},
              onFilterTap: onFilterTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders EmptyState when listings is empty', (tester) async {
    await tester.pumpWidget(
      host(data: const SearchState(filter: SearchFilter(query: 'foo'))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('renders the chip-bar header when listings has rows', (
    tester,
  ) async {
    final state = SearchState(
      filter: const SearchFilter(query: 'bike'),
      listings: [makeListing()],
      total: 1,
    );
    await tester.pumpWidget(host(data: state));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });
}
