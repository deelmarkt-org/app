import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/cards/deel_card_image.dart';
import 'package:deelmarkt/widgets/price/price_tag.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

import 'deel_card_test_helper.dart';

void main() {
  group('DeelCard.grid rendering', () {
    testWidgets('renders price, title, and image', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 2500,
            title: 'Vintage Chair',
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(PriceTag), findsOneWidget);
      expect(find.text('Vintage Chair'), findsOneWidget);
      expect(find.byType(DeelCardImage), findsOneWidget);
    });

    testWidgets('shows location when provided', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1000,
            title: 'Lamp',
            onTap: () {},
            location: 'Amsterdam',
            distanceFormatted: '2.5 km',
          ),
        ),
      );

      expect(find.textContaining('Amsterdam'), findsOneWidget);
      expect(find.textContaining('2.5 km'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 500,
            title: 'Book',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(DeelCard));
      expect(tapped, isTrue);
    });
  });

  group('DeelCard.list rendering', () {
    testWidgets('renders in list layout', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.list(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1500,
            title: 'Table',
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(PriceTag), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
    });

    testWidgets('list variant has thumbnail size constraint', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: DeelCard.list(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 1500,
            title: 'Table',
            onTap: () {},
          ),
        ),
      );

      // Verify the outer SizedBox has list thumbnail height
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasListHeight = sizedBoxes.any(
        (sb) => sb.height == DeelCardTokens.listThumbnailSize,
      );
      expect(hasListHeight, isTrue);
    });
  });

  group('DeelCard dark mode', () {
    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          theme: DeelmarktTheme.dark,
          child: DeelCard.grid(
            imageUrl: 'https://example.com/img.jpg',
            priceInCents: 2000,
            title: 'Dark Item',
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(DeelCard), findsOneWidget);
    });
  });
}
