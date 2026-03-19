import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import 'deel_button_test_helper.dart';

void main() {
  group('DeelButton rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(label: 'Koop nu', onPressed: null),
        ),
      );

      expect(find.text('Koop nu'), findsOneWidget);
    });

    testWidgets('large size has minimum height of 52px', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Test',
            onPressed: null,
            size: DeelButtonSize.large,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(DeelButton));
      expect(buttonSize.height, greaterThanOrEqualTo(52));
    });

    testWidgets('medium size has minimum height of 44px', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Test',
            onPressed: null,
            size: DeelButtonSize.medium,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(DeelButton));
      expect(buttonSize.height, greaterThanOrEqualTo(44));
    });

    testWidgets('small size has minimum height of 36px', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Test',
            onPressed: null,
            size: DeelButtonSize.small,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(DeelButton));
      expect(buttonSize.height, greaterThanOrEqualTo(36));
    });

    testWidgets('fullWidth true expands to parent width', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Full width',
            onPressed: null,
            fullWidth: true,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.width, greaterThan(300));
    });
  });

  group('DeelButton variants', () {
    testWidgets('primary renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Primary',
            onPressed: null,
            variant: DeelButtonVariant.primary,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('secondary renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Secondary',
            onPressed: null,
            variant: DeelButtonVariant.secondary,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('outline renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Outline',
            onPressed: null,
            variant: DeelButtonVariant.outline,
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('ghost renders TextButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Ghost',
            onPressed: null,
            variant: DeelButtonVariant.ghost,
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('destructive renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Delete',
            onPressed: null,
            variant: DeelButtonVariant.destructive,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('success renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(
            label: 'Confirm',
            onPressed: null,
            variant: DeelButtonVariant.success,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
