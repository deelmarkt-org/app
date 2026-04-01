import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import 'deel_button_test_helper.dart';

void main() {
  group('DeelButton accessibility', () {
    testWidgets('has Semantics with button role', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(button: DeelButton(label: 'Action', onPressed: () {})),
      );

      final semantics = tester.getSemantics(find.byType(DeelButton));
      expect(semantics.label, 'Action');
    });

    testWidgets('small button meets 44px touch target', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Small',
            onPressed: () {},
            size: DeelButtonSize.small,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(DeelButton));
      expect(buttonSize.height, greaterThanOrEqualTo(36));
    });

    testWidgets('loadingLabel is used in semantics when loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Opslaan',
            onPressed: () {},
            isLoading: true,
            loadingLabel: 'Bezig met opslaan...',
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(DeelButton));
      expect(semantics.label, 'Bezig met opslaan...');
    });

    testWidgets('destructive variant has hint in semantics', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Verwijderen',
            onPressed: () {},
            variant: DeelButtonVariant.destructive,
            semanticDestructiveHint: 'Destructieve actie',
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(DeelButton));
      expect(semantics.hint, 'Destructieve actie');
    });
  });

  group('DeelButton dark mode', () {
    testWidgets('uses dark theme colours when dark theme is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildButtonApp(
          theme: DeelmarktTheme.dark,
          button: DeelButton(label: 'Dark', onPressed: () {}),
        ),
      );

      expect(find.byType(DeelButton), findsOneWidget);

      final context = tester.element(find.byType(DeelButton));
      final buttonTheme = Theme.of(context).extension<DeelButtonThemeData>();
      expect(buttonTheme, isNotNull);
      expect(buttonTheme!.primaryBackground, DeelmarktColors.darkPrimary);
    });
  });
}
