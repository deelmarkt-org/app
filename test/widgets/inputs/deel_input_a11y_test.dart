import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/inputs/deel_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('DeelInput accessibility', () {
    testWidgets('has Semantics with label', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'E-mailadres')),
      );

      // Verify the label text is rendered (visible label above field).
      expect(find.text('E-mailadres'), findsOneWidget);

      // Verify TextFormField is in the widget tree and accessible.
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('required field label includes asterisk', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'Naam', isRequired: true)),
      );

      // The label text should contain *.
      expect(find.text('Naam *'), findsAtLeast(1));
    });

    testWidgets('touch target meets 44px minimum', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'Test')),
      );

      // Find the ConstrainedBox that wraps the TextFormField.
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(DeelInput),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('error text is displayed via InputDecoration', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(
            label: 'E-mail',
            errorText: 'Ongeldig e-mailadres',
          ),
        ),
      );

      // Error text rendered by InputDecoration (native Flutter a11y).
      expect(find.text('Ongeldig e-mailadres'), findsOneWidget);
    });

    testWidgets('disabled state has reduced opacity', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'Disabled', enabled: false),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.4);
    });
  });
}
