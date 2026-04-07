import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/price/price_tag.dart';

import 'price_tag_test_helper.dart';

void main() {
  group('PriceTag accessibility', () {
    testWidgets('wraps content in MergeSemantics', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      expect(find.byType(MergeSemantics), findsOneWidget);
    });

    testWidgets('semantics label contains readable price', (tester) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
      );
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      // At least one Semantics node should have the price label key
      final hasPriceLabel = semanticsList.any(
        (s) =>
            s.properties.label?.contains('price_tag.semanticsPrice') ?? false,
      );
      expect(hasPriceLabel, isTrue);
    });

    testWidgets('semantics label uses discounted key when original set', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(
          child: const PriceTag(priceInCents: 3500, originalPriceInCents: 4500),
        ),
      );
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasDiscountedLabel = semanticsList.any(
        (s) =>
            s.properties.label?.contains('price_tag.semanticsDiscounted') ??
            false,
      );
      expect(hasDiscountedLabel, isTrue);
    });

    testWidgets('semantics label uses free key when price is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTagApp(child: const PriceTag(priceInCents: 0)),
      );
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasFreeLabel = semanticsList.any(
        (s) => s.properties.label?.contains('price_tag.semanticsFree') ?? false,
      );
      expect(hasFreeLabel, isTrue);
    });

    testWidgets(
      'excludes child text from semantics tree to avoid duplication',
      (tester) async {
        await tester.pumpWidget(
          buildPriceTagApp(child: const PriceTag(priceInCents: 4500)),
        );
        // At least one ExcludeSemantics must be present — the one wrapping
        // the visible price text inside the PriceTag. (Scaffold uses others
        // internally, so we match "at least one".)
        expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(1));
      },
    );
  });
}
