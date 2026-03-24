import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/inputs/deel_postcode_formatter.dart';
import 'package:deelmarkt/widgets/inputs/deel_postcode_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('PostcodeInputFormatter.isValid', () {
    test('valid postcode: 1012 AB', () {
      expect(PostcodeInputFormatter.isValid('1012 AB'), isTrue);
    });

    test('valid postcode without space: 1012AB', () {
      expect(PostcodeInputFormatter.isValid('1012AB'), isTrue);
    });

    test('invalid: starts with 0', () {
      expect(PostcodeInputFormatter.isValid('0123 AB'), isFalse);
    });

    test('invalid: forbidden letters SA', () {
      expect(PostcodeInputFormatter.isValid('1234 SA'), isFalse);
    });

    test('invalid: forbidden letters SD', () {
      expect(PostcodeInputFormatter.isValid('1234 SD'), isFalse);
    });

    test('invalid: forbidden letters SS', () {
      expect(PostcodeInputFormatter.isValid('1234 SS'), isFalse);
    });

    test('invalid: too short', () {
      expect(PostcodeInputFormatter.isValid('1012'), isFalse);
    });

    test('invalid: only letters', () {
      expect(PostcodeInputFormatter.isValid('ABCD EF'), isFalse);
    });

    test('valid: lowercase normalised', () {
      expect(PostcodeInputFormatter.isValid('1012 ab'), isTrue);
    });
  });

  group('DeelPostcodeInput widget', () {
    testWidgets('renders label and hint', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelPostcodeInput(label: 'Postcode')),
      );

      expect(find.text('Postcode'), findsOneWidget);
      expect(find.text('input.postcode_hint'), findsOneWidget);
    });

    testWidgets('onValidPostcode fires for valid input', (tester) async {
      String? validPostcode;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPostcodeInput(
            label: 'Postcode',
            onValidPostcode: (v) => validPostcode = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '1012AB');
      await tester.pump();
      expect(validPostcode, '1012 AB');
    });

    testWidgets('onValidPostcode does NOT fire for partial input', (
      tester,
    ) async {
      String? validPostcode;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPostcodeInput(
            label: 'Postcode',
            onValidPostcode: (v) => validPostcode = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '1012');
      await tester.pump();
      expect(validPostcode, isNull);
    });

    testWidgets('onValidPostcode does NOT fire for forbidden letters', (
      tester,
    ) async {
      String? validPostcode;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelPostcodeInput(
            label: 'Postcode',
            onValidPostcode: (v) => validPostcode = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '1234SA');
      await tester.pump();
      expect(validPostcode, isNull);
    });

    testWidgets('renders error text', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelPostcodeInput(
            label: 'Postcode',
            errorText: 'Ongeldige postcode',
          ),
        ),
      );

      expect(find.text('Ongeldige postcode'), findsOneWidget);
    });
  });
}
