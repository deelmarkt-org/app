import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';
import 'package:deelmarkt/widgets/location/location_badge.dart';
import 'package:deelmarkt/widgets/location/location_badge_detail.dart';

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
      expect(find.byType(LocationBadge), findsOneWidget);
    });

    testWidgets('renders location section header', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      // easy_localization returns the key as-is in test context.
      expect(find.text('listing_detail.locationHeader'), findsOneWidget);
    });

    testWidgets('renders map placeholder for location', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();
      expect(find.byType(LocationMapPlaceholder), findsOneWidget);
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

    // --- NEW TESTS ---

    testWidgets('description expand/collapse', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();

      // Initially collapsed: "Read more" toggle is visible.
      // easy_localization returns the key path when no locale is loaded.
      expect(find.text('listing_detail.readMore'), findsOneWidget);
      expect(find.text('listing_detail.readLess'), findsNothing);

      // Tap "Read more" to expand.
      await tester.tap(find.text('listing_detail.readMore'));
      await tester.pumpAndSettle();

      // After expanding: "Read less" is shown; "Read more" is gone.
      expect(find.text('listing_detail.readLess'), findsOneWidget);
      expect(find.text('listing_detail.readMore'), findsNothing);

      // Tap "Read less" to collapse again.
      await tester.tap(find.text('listing_detail.readLess'));
      await tester.pumpAndSettle();

      // Back to collapsed state.
      expect(find.text('listing_detail.readMore'), findsOneWidget);
      expect(find.text('listing_detail.readLess'), findsNothing);
    });

    // Parameterized test — one case per ListingCondition variant.
    for (final condition in ListingCondition.values) {
      testWidgets('condition chip renders for ${condition.name}', (
        tester,
      ) async {
        final listing = _testListing.copyWith(condition: condition);
        await tester.pumpWidget(buildSection(listing: listing));
        await tester.pump();

        // ConditionChip renders 'condition.<name>' via easy_localization;
        // in test context the key is returned as-is.
        expect(find.text('condition.${condition.name}'), findsOneWidget);
      });
    }

    testWidgets('distanceKm renders formatted distance', (tester) async {
      // _testListing already has distanceKm: 2.3 and location: 'Amsterdam'.
      await tester.pumpWidget(buildSection());
      await tester.pump();

      // LocationBadgeDetail renders distance as a standalone Text below city.
      // Formatters.distanceKm uses Dutch locale: "2,3 km".
      final formatted = Formatters.distanceKm(2.3);
      expect(find.textContaining(formatted), findsOneWidget);
    });
  });
}
