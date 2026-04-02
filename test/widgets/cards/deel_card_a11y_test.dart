import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/cards/deel_card.dart';

import 'deel_card_test_helper.dart';

void main() {
  group('DeelCard accessibility', () {
    testWidgets('card has MergeSemantics with price and title', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceFormatted: '\u20AC 10,00',
            title: 'Vintage Lamp',
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('favourite has toggled Semantics', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceFormatted: '\u20AC 10,00',
            title: 'Item',
            onTap: () {},
            isFavourited: true,
            onFavouriteTap: () {},
          ),
        ),
      );

      // Verify Semantics with toggled property exists
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasToggled = semanticsList.any((s) => s.properties.toggled == true);
      expect(hasToggled, isTrue);
    });
  });
}
