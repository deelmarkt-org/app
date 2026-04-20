import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
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
  Widget buildView({required SearchState data}) {
    return ProviderScope(
      overrides: [
        // GH-59: EscrowAwareListingCard reads the Unleash flag — override
        // it here so widget tests don't try to contact the real SDK.
        isFeatureEnabledProvider(
          FeatureFlags.listingsEscrowBadge,
        ).overrideWith((ref) => false),
      ],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: SearchResultsView(
            data: data,
            onListingTap: (_) {},
            onFavouriteTap: (_) {},
            onLoadMore: () {},
            onFilterTap: () {},
          ),
        ),
      ),
    );
  }

  group('SearchResultsView', () {
    testWidgets('shows empty state when no listings', (tester) async {
      await tester.pumpWidget(
        buildView(data: const SearchState(filter: SearchFilter(query: 'xyz'))),
      );
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows results count and grid', (tester) async {
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
    });

    testWidgets('shows filter chips row', (tester) async {
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
      // Filter chips rendered in horizontal scroll (viewport may clip some)
      expect(find.byType(ActionChip), findsAtLeast(3));
    });

    testWidgets('shows loading indicator when isLoadingMore', (tester) async {
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
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFeatureEnabledProvider(
              FeatureFlags.listingsEscrowBadge,
            ).overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: Scaffold(
              body: SearchResultsView(
                data: SearchState(
                  listings: [_testListing],
                  filter: const SearchFilter(query: 'test'),
                  total: 1,
                ),
                onListingTap: (_) {},
                onFavouriteTap: (_) {},
                onLoadMore: () {},
                onFilterTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SearchResultsView), findsOneWidget);
    });
  });
}
