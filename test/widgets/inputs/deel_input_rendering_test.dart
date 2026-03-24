import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('DeelInput rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'E-mailadres')),
      );

      expect(find.text('E-mailadres'), findsOneWidget);
    });

    testWidgets('renders required marker when isRequired is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'E-mailadres', isRequired: true),
        ),
      );

      expect(find.text('E-mailadres *'), findsAtLeast(1));
    });

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'Naam', hint: 'Je volledige naam'),
        ),
      );

      expect(find.text('Je volledige naam'), findsOneWidget);
    });

    testWidgets('renders error text below field', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(
            label: 'E-mail',
            errorText: 'Ongeldig e-mailadres',
          ),
        ),
      );

      expect(find.text('Ongeldig e-mailadres'), findsOneWidget);
    });

    testWidgets('renders prefix icon', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'Test', prefixIcon: Icon(Icons.search)),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders suffix icon', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'Test', suffixIcon: Icon(Icons.clear)),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });

  group('DeelInput disabled state', () {
    testWidgets('disabled input has reduced opacity', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'Disabled', enabled: false),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.4);
    });

    testWidgets('enabled input has full opacity', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'Enabled')),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });

  group('DeelInput readOnly state', () {
    testWidgets('readOnly field renders without error', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: const DeelInput(label: 'ReadOnly', readOnly: true),
        ),
      );

      // Verify the widget renders and contains a TextFormField.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('ReadOnly'), findsOneWidget);
    });
  });

  group('DeelInput dark mode', () {
    testWidgets('renders correctly with dark theme', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          theme: DeelmarktTheme.dark,
          child: const DeelInput(label: 'Dark'),
        ),
      );

      expect(find.text('Dark'), findsOneWidget);
    });
  });
}
