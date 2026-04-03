import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/listings_tab_view.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final testListings = [
    ListingEntity(
      id: 'listing-001',
      title: 'Test Bike',
      description: 'A nice bike',
      priceInCents: 15000,
      sellerId: 'user-1',
      sellerName: 'Jan',
      condition: ListingCondition.good,
      categoryId: 'cat-1',
      imageUrls: const ['https://example.com/bike.jpg'],
      createdAt: DateTime(2026),
      location: 'Amsterdam',
    ),
  ];

  group('ListingsTabView navigation wiring', () {
    testWidgets('#51 — empty state onAction callback is wired', (tester) async {
      await pumpTestWidget(
        tester,
        ListingsTabView(
          listings: const AsyncValue<List<ListingEntity>>.data([]),
          onRetry: () {},
        ),
      );

      final emptyState = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(emptyState.variant, EmptyStateVariant.myListings);

      expect(find.text('empty.my_listings_action'), findsOneWidget);
    });

    testWidgets('#52 — listing cards have onTap wired', (tester) async {
      await pumpTestWidget(
        tester,
        ListingsTabView(
          listings: AsyncValue<List<ListingEntity>>.data(testListings),
          onRetry: () {},
        ),
      );

      expect(find.byType(DeelCard), findsOneWidget);
      expect(find.text('Test Bike'), findsOneWidget);
    });
  });
}
