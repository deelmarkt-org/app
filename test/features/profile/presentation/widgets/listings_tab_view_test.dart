import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/listings_tab_view.dart';
import 'package:deelmarkt/widgets/cards/deel_card_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ListingsTabView', () {
    testWidgets('loading state shows DeelCardSkeleton widgets', (tester) async {
      // Use pump() instead of pumpAndSettle() because the skeleton shimmer
      // animation never settles, causing pumpAndSettle to time out.
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ListingsTabView(
                listings: AsyncValue<List<ListingEntity>>.loading(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DeelCardSkeleton), findsWidgets);
    });

    testWidgets('empty data state shows EmptyState', (tester) async {
      await pumpTestWidget(
        tester,
        const ListingsTabView(
          listings: AsyncValue<List<ListingEntity>>.data([]),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('error state shows ErrorState', (tester) async {
      await pumpTestWidget(
        tester,
        ListingsTabView(
          listings: AsyncValue<List<ListingEntity>>.error(
            Exception('fail'),
            StackTrace.current,
          ),
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('data state with items shows listing titles', (tester) async {
      final listings = [
        ListingEntity(
          id: '1',
          title: 'Test Listing One',
          description: 'A test listing',
          priceInCents: 4500,
          sellerId: 'user-1',
          sellerName: 'Jan',
          condition: ListingCondition.good,
          categoryId: 'cat-1',
          imageUrls: const ['https://example.com/img.jpg'],
          createdAt: DateTime(2026),
          location: 'Amsterdam',
        ),
        ListingEntity(
          id: '2',
          title: 'Test Listing Two',
          description: 'Another test listing',
          priceInCents: 1200,
          sellerId: 'user-1',
          sellerName: 'Jan',
          condition: ListingCondition.likeNew,
          categoryId: 'cat-2',
          imageUrls: const [],
          createdAt: DateTime(2026, 2),
          location: 'Rotterdam',
        ),
      ];

      await pumpTestWidget(
        tester,
        ListingsTabView(
          listings: AsyncValue<List<ListingEntity>>.data(listings),
        ),
      );

      expect(find.text('Test Listing One'), findsOneWidget);
      expect(find.text('Test Listing Two'), findsOneWidget);
    });

    testWidgets('data state shows formatted price', (tester) async {
      final listings = [
        ListingEntity(
          id: '1',
          title: 'Priced Item',
          description: 'Item with price',
          priceInCents: 4500,
          sellerId: 'user-1',
          sellerName: 'Jan',
          condition: ListingCondition.good,
          categoryId: 'cat-1',
          imageUrls: const [],
          createdAt: DateTime(2026),
        ),
      ];

      await pumpTestWidget(
        tester,
        ListingsTabView(
          listings: AsyncValue<List<ListingEntity>>.data(listings),
        ),
      );

      // Price is formatted as "euro-sign 45.00"
      expect(find.textContaining('45.00'), findsOneWidget);
    });
  });
}
