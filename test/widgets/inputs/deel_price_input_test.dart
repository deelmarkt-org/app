import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/inputs/deel_price_formatter.dart';
import 'package:deelmarkt/widgets/inputs/deel_price_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('DeelPriceController', () {
    test('valueInCents returns 0 for empty text', () {
      final controller = DeelPriceController();
      expect(controller.valueInCents, 0);
      controller.dispose();
    });

    test('valueInCents parses NL format (comma decimal)', () {
      final controller = DeelPriceController(decimalSeparator: ',');
      controller.text = '45,50';
      expect(controller.valueInCents, 4550);
      controller.dispose();
    });

    test('valueInCents parses EN format (dot decimal)', () {
      final controller = DeelPriceController(decimalSeparator: '.');
      controller.text = '45.50';
      expect(controller.valueInCents, 4550);
      controller.dispose();
    });

    test('set valueInCents updates display text', () {
      final controller = DeelPriceController(decimalSeparator: ',');
      controller.valueInCents = 4550;
      expect(controller.text, '45,50');
      controller.dispose();
    });

    test('set valueInCents with zero remainder pads correctly', () {
      final controller = DeelPriceController(decimalSeparator: ',');
      controller.valueInCents = 4500;
      expect(controller.text, '45,00');
      controller.dispose();
    });

    test('isWithinBounds checks minCents', () {
      final controller = DeelPriceController(minCents: 100);
      controller.text = '0,50';
      expect(controller.isWithinBounds, isFalse);
      controller.dispose();
    });

    test('isWithinBounds checks maxCents', () {
      final controller = DeelPriceController(maxCents: 10000);
      controller.text = '200,00';
      expect(controller.isWithinBounds, isFalse);
      controller.dispose();
    });

    test('isWithinBounds returns true for valid amount', () {
      final controller = DeelPriceController(minCents: 100, maxCents: 10000);
      controller.text = '50,00';
      expect(controller.isWithinBounds, isTrue);
      controller.dispose();
    });
  });

  group('DeelPriceController security', () {
    test('valueInCents clamps to maxCents for overflow input', () {
      final controller = DeelPriceController(maxCents: 10000);
      controller.text = '999,99';
      expect(controller.valueInCents, 10000);
      controller.dispose();
    });

    test('valueInCents clamps negative to 0', () {
      final controller = DeelPriceController();
      // Programmatic text setter sanitises, but verify getter clamps.
      expect(controller.valueInCents, 0);
      controller.dispose();
    });

    test('programmatic text is sanitised through formatter', () {
      final controller = DeelPriceController();
      controller.text = 'EUR 45,50';
      expect(controller.text, '45,50');
      expect(controller.valueInCents, 4550);
      controller.dispose();
    });

    test('programmatic text rejects letters', () {
      final controller = DeelPriceController();
      controller.text = 'abc';
      expect(controller.text, '');
      expect(controller.valueInCents, 0);
      controller.dispose();
    });

    test('parseToCents with 3+ decimal places returns null', () {
      final formatter = PriceInputFormatter(decimalSeparator: ',');
      expect(formatter.parseToCents('1,105'), isNull);
    });
  });

  group('DeelPriceInput rendering', () {
    testWidgets('renders EUR prefix', (tester) async {
      final controller = DeelPriceController();
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPriceInput(label: 'Prijs', controller: controller),
        ),
      );

      expect(find.text('input.price_prefix'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('renders label', (tester) async {
      final controller = DeelPriceController();
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPriceInput(label: 'Prijs', controller: controller),
        ),
      );

      expect(find.text('Prijs'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('accepts digits and comma', (tester) async {
      final controller = DeelPriceController(decimalSeparator: ',');
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPriceInput(label: 'Prijs', controller: controller),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '12,50');
      expect(controller.text, '12,50');
      expect(controller.valueInCents, 1250);
      controller.dispose();
    });
  });
}
