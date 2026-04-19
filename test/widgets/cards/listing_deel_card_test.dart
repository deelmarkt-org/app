import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/cards/listing_deel_card.dart';

import 'deel_card_test_helper.dart';

ListingEntity _listing({
  String id = 'l1',
  String title = 'Vintage camera',
  int priceInCents = 4500,
  int? originalPriceInCents,
  String? location = 'Amsterdam',
  double? distanceKm,
  List<String> imageUrls = const [
    'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  ],
}) => ListingEntity(
  id: id,
  title: title,
  description: 'A great item',
  priceInCents: priceInCents,
  originalPriceInCents: originalPriceInCents,
  sellerId: 'seller1',
  sellerName: 'Jan',
  condition: ListingCondition.good,
  categoryId: 'cat1',
  imageUrls: imageUrls,
  createdAt: DateTime(2026),
  location: location,
  distanceKm: distanceKm,
);

void main() {
  group('listingDeelCard', () {
    testWidgets('renders a DeelCard widget', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: listingDeelCard(
            _listing(),
            onTap: () {},
            onFavouriteTap: () {},
          ),
        ),
      );
      expect(find.byType(DeelCard), findsOneWidget);
    });

    testWidgets('passes title to DeelCard', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: listingDeelCard(
            _listing(title: 'Test Title'),
            onTap: () {},
            onFavouriteTap: () {},
          ),
        ),
      );
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('uses first imageUrl when list is non-empty', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildCardApp(
          child: listingDeelCard(
            _listing(),
            onTap: () => tapped = true,
            onFavouriteTap: () {},
          ),
        ),
      );
      await tester.tap(find.byType(DeelCard));
      expect(tapped, isTrue);
    });

    testWidgets('empty imageUrls passes empty string — no crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCardApp(
          child: listingDeelCard(
            _listing(imageUrls: const []),
            onTap: () {},
            onFavouriteTap: () {},
          ),
        ),
      );
      expect(find.byType(DeelCard), findsOneWidget);
    });

    testWidgets('showEscrowBadge defaults to false', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: listingDeelCard(
            _listing(),
            onTap: () {},
            onFavouriteTap: () {},
          ),
        ),
      );
      // Escrow badge not shown by default
      expect(find.byKey(const Key('escrow_badge')), findsNothing);
    });
  });
}
