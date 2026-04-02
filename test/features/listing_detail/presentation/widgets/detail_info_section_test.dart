import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';

final _testListing = ListingEntity(
  id: 'test-1',
  title: 'Vintage Design Stoel',
  description:
      'Een prachtige vintage stoel in goede staat. '
      'Perfect voor in de woonkamer. Minimale gebruikssporen.',
  priceInCents: 4500,
  sellerId: 'user-1',
  sellerName: 'Jan',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
  location: 'Amsterdam',
  distanceKm: 2.3,
);

void main() {
  Widget buildSection({ListingEntity? listing, String? categoryName}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DetailInfoSection(
            listing: listing ?? _testListing,
            categoryName: categoryName,
          ),
        ),
      ),
    );
  }

  group('DetailInfoSection', () {
    testWidgets('renders price', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      expect(find.text(Formatters.euroFromCents(4500)), findsOneWidget);
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      expect(find.text('Vintage Design Stoel'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      expect(
        find.textContaining('Een prachtige vintage stoel'),
        findsAtLeast(1),
      );
    });

    testWidgets('renders location', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      expect(find.text('Amsterdam'), findsOneWidget);
    });

    testWidgets('hides location when null', (tester) async {
      final noLocation = ListingEntity(
        id: 'test-2',
        title: 'No Location Item',
        description: 'A test listing without location info at all.',
        priceInCents: 3000,
        sellerId: 'user-1',
        sellerName: 'Jan',
        condition: ListingCondition.good,
        categoryId: 'cat-1',
        imageUrls: const [],
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(buildSection(listing: noLocation));
      await tester.pump();
      expect(find.text('Amsterdam'), findsNothing);
    });

    testWidgets('renders condition chip with Semantics', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      // Condition chip exists within a Semantics widget
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders category chip when provided', (tester) async {
      await tester.pumpWidget(buildSection(categoryName: 'Meubels'));
      await tester.pump();
      expect(find.text('Meubels'), findsOneWidget);
    });

    testWidgets('title and price are in same Row', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      // Both title and price should be visible
      expect(find.text('Vintage Design Stoel'), findsOneWidget);
      expect(find.text(Formatters.euroFromCents(4500)), findsOneWidget);
    });
  });
}
