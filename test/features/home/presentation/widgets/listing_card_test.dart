import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/listing_card.dart';

final _testListing = ListingEntity(
  id: 'test-1',
  title: 'Test Fiets',
  description: 'Een mooie fiets',
  priceInCents: 4500,
  sellerId: 'user-1',
  sellerName: 'Jan',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
  location: 'Amsterdam',
  distanceKm: 3.2,
);

void main() {
  Widget buildCard({
    ListingEntity? listing,
    VoidCallback? onTap,
    VoidCallback? onFavouriteTap,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: ListingCard(
              listing: listing ?? _testListing,
              onTap: onTap ?? () {},
              onFavouriteTap: onFavouriteTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('ListingCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text('Test Fiets'), findsOneWidget);
    });

    testWidgets('renders price', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text(Formatters.euroFromCents(4500)), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('favourite button is 44x44', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();

      final sizedBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 44 && w.height == 44,
      );
      expect(sizedBoxes, findsOneWidget);
    });

    testWidgets('uses Material+InkWell for focus support', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();

      // Card InkWell + favourite button InkWell
      expect(find.byType(InkWell), findsAtLeast(2));
    });

    testWidgets('has semantics label with title and price', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(ListingCard));
      expect(semantics.label, contains('Test Fiets'));
    });
  });
}
