import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_listing_tile.dart';

final _activeListing = ListingEntity(
  id: 'list-1',
  title: 'Vintage Camera',
  description: 'Great condition camera',
  priceInCents: 7500,
  sellerId: 'seller-1',
  sellerName: 'Jan',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
  viewCount: 12,
  favouriteCount: 3,
);

Widget buildTile({ListingEntity? listing, VoidCallback? onTap}) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: Scaffold(
      body: SellerListingTile(
        listing: listing ?? _activeListing,
        onTap: onTap ?? () {},
      ),
    ),
  );
}

void main() {
  group('SellerListingTile', () {
    testWidgets('renders listing title', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.pump();

      expect(find.text('Vintage Camera'), findsOneWidget);
    });

    testWidgets('renders price using Formatters.euroFromCents', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.pump();

      expect(find.text(Formatters.euroFromCents(7500)), findsOneWidget);
    });

    testWidgets('renders view count', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders favourite count', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTile(onTap: () => tapped = true));
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders sold listing without error', (tester) async {
      final soldListing = _activeListing.copyWith(status: ListingStatus.sold);
      await tester.pumpWidget(buildTile(listing: soldListing));
      await tester.pump();

      expect(find.byType(SellerListingTile), findsOneWidget);
    });

    testWidgets('renders draft listing without error', (tester) async {
      final draftListing = _activeListing.copyWith(status: ListingStatus.draft);
      await tester.pumpWidget(buildTile(listing: draftListing));
      await tester.pump();

      expect(find.byType(SellerListingTile), findsOneWidget);
    });

    testWidgets('renders dark mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: Scaffold(
            body: SellerListingTile(listing: _activeListing, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SellerListingTile), findsOneWidget);
    });
  });
}
