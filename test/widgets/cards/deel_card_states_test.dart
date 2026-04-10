import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

import 'deel_card_test_helper.dart';

void main() {
  group('DeelCard favourite toggle', () {
    testWidgets('shows filled heart when favourited', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
            isFavourited: true,
            onFavouriteTap: () {},
          ),
        ),
      );

      expect(
        find.byIcon(PhosphorIcons.heart(PhosphorIconsStyle.fill)),
        findsOneWidget,
      );
    });

    testWidgets('shows outline heart when not favourited', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
            onFavouriteTap: () {},
          ),
        ),
      );

      expect(find.byIcon(PhosphorIcons.heart()), findsOneWidget);
    });

    testWidgets('fires onFavouriteTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
            onFavouriteTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).last);
      expect(tapped, isTrue);
    });

    testWidgets('no favourite button when onFavouriteTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(PhosphorIcons.heart()), findsNothing);
      expect(
        find.byIcon(PhosphorIcons.heart(PhosphorIconsStyle.fill)),
        findsNothing,
      );
    });
  });

  group('DeelCard escrow badge', () {
    testWidgets('shows escrow badge when enabled', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
            showEscrowBadge: true,
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsOneWidget);
    });

    testWidgets('no escrow badge by default', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Item',
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsNothing);
    });
  });
}
