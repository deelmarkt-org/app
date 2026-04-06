import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/widgets/price/price_tag.dart';

import 'price_tag_test_helper.dart';

void main() {
  group('PriceTag rendering', () {
    testWidgets('renders formatted Euro price (normal size)', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      // Dutch locale: "€ 45,00" (non-breaking space between symbol and number)
      expect(find.textContaining('45,00'), findsOneWidget);
      expect(find.textContaining('\u20AC'), findsOneWidget);
    });

    testWidgets('renders formatted Euro price (small size)', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 10050, size: PriceTagSize.small),
        ),
      );
      expect(find.textContaining('100,50'), findsOneWidget);
    });

    testWidgets('normal size uses 20px font (DeelmarktTypography.price)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      final textWidget = tester.widget<Text>(find.textContaining('45,00'));
      expect(textWidget.style?.fontSize, DeelmarktTypography.price.fontSize);
    });

    testWidgets('small size uses 16px font (DeelmarktTypography.priceSm)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 4500, size: PriceTagSize.small),
        ),
      );
      final textWidget = tester.widget<Text>(find.textContaining('45,00'));
      expect(textWidget.style?.fontSize, DeelmarktTypography.priceSm.fontSize);
    });

    testWidgets('zero price shows "Gratis" key', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 0)),
      );
      expect(find.text('price_tag.free'), findsOneWidget);
    });

    testWidgets('shows inclBtw subtitle when showBtw=true, btwInclusive=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 4500, showBtw: true),
        ),
      );
      expect(find.text('price_tag.inclBtw'), findsOneWidget);
    });

    testWidgets('shows exclBtw subtitle when btwInclusive=false', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(
            priceInCents: 4500,
            showBtw: true,
            btwInclusive: false,
          ),
        ),
      );
      expect(find.text('price_tag.exclBtw'), findsOneWidget);
    });

    testWidgets('hides BTW subtitle when showBtw=false', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      expect(find.text('price_tag.inclBtw'), findsNothing);
      expect(find.text('price_tag.exclBtw'), findsNothing);
    });

    testWidgets(
      'shows strikethrough when originalPriceInCents > priceInCents',
      (tester) async {
        await tester.pumpWidget(
          buildPriceTagApp(
            child: const PriceTag(
              priceInCents: 3500,
              originalPriceInCents: 4500,
            ),
          ),
        );
        // Both prices visible
        expect(find.textContaining('35,00'), findsOneWidget);
        expect(find.textContaining('45,00'), findsOneWidget);
      },
    );

    testWidgets('strikethrough uses lineThrough decoration', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 3500, originalPriceInCents: 4500),
        ),
      );
      final originalText = tester.widget<Text>(find.textContaining('45,00'));
      expect(originalText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('no strikethrough when originalPriceInCents == priceInCents', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 4500, originalPriceInCents: 4500),
        ),
      );
      // Only one price text should appear (no strikethrough duplicate)
      expect(find.textContaining('45,00'), findsOneWidget);
    });

    testWidgets('no strikethrough when originalPriceInCents is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      expect(find.textContaining('45,00'), findsOneWidget);
    });

    testWidgets('uses tabular figures font feature', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      final textWidget = tester.widget<Text>(find.textContaining('45,00'));
      expect(
        textWidget.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('discounted price uses primary color', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 3500, originalPriceInCents: 4500),
        ),
      );
      final currentText = tester.widget<Text>(find.textContaining('35,00'));
      expect(currentText.style?.color, DeelmarktColors.primary);
    });

    testWidgets('free price uses primary color', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 0)),
      );
      final freeText = tester.widget<Text>(find.text('price_tag.free'));
      expect(freeText.style?.color, DeelmarktColors.primary);
    });

    testWidgets('renders without errors in dark mode', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          theme: DeelmarktTheme.dark,
          child: const PriceTag(priceInCents: 4500),
        ),
      );
      expect(find.byType(PriceTag), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
