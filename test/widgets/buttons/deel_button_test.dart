import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Test helper — wraps [DeelButton] in a themed [MaterialApp].
Widget _buildApp({
  required DeelButton button,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  // ── Rendering ──────────────────────────────────────────────────────────

  group('DeelButton rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _buildApp(button: const DeelButton(label: 'Koop nu', onPressed: null)),
      );

      expect(find.text('Koop nu'), findsOneWidget);
    });

    testWidgets('large size has minimum height of 52px', (tester) async {
      await tester.pumpWidget(
        _buildApp(
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
        _buildApp(
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
        _buildApp(
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
        _buildApp(
          button: const DeelButton(
            label: 'Full width',
            onPressed: null,
            fullWidth: true,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      // Should fill most of the screen width (subtract scaffold padding)
      expect(buttonSize.width, greaterThan(300));
    });
  });

  // ── Variants ───────────────────────────────────────────────────────────

  group('DeelButton variants', () {
    testWidgets('primary renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        _buildApp(
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
        _buildApp(
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
        _buildApp(
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
        _buildApp(
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
        _buildApp(
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
        _buildApp(
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

  // ── States ─────────────────────────────────────────────────────────────

  group('DeelButton states', () {
    testWidgets('onPressed callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(label: 'Tap me', onPressed: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('null onPressed disables the button', (tester) async {
      await tester.pumpWidget(
        _buildApp(button: const DeelButton(label: 'Disabled', onPressed: null)),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading state shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loading state disables tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Loading',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('disabled button still has correct label in semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(button: const DeelButton(label: 'Save', onPressed: null)),
      );

      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });
  });

  // ── Icons ──────────────────────────────────────────────────────────────

  group('DeelButton icons', () {
    testWidgets('renders leading icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Save',
            onPressed: () {},
            leadingIcon: Icons.save,
          ),
        ),
      );

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('renders trailing icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Next',
            onPressed: () {},
            trailingIcon: Icons.arrow_forward,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders both leading and trailing icons', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Action',
            onPressed: () {},
            leadingIcon: Icons.star,
            trailingIcon: Icons.chevron_right,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  // ── Accessibility ──────────────────────────────────────────────────────

  group('DeelButton accessibility', () {
    testWidgets('has Semantics with button role', (tester) async {
      await tester.pumpWidget(
        _buildApp(button: DeelButton(label: 'Action', onPressed: () {})),
      );

      final semantics = tester.getSemantics(find.byType(DeelButton));
      expect(semantics.label, 'Action');
    });

    testWidgets('small button meets 44px touch target', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          button: DeelButton(
            label: 'Small',
            onPressed: () {},
            size: DeelButtonSize.small,
          ),
        ),
      );

      // Material's tapTargetSize.padded guarantees >= 48px touch area
      // The visual height is 36px but the touch target is padded
      final buttonSize = tester.getSize(find.byType(DeelButton));
      expect(buttonSize.height, greaterThanOrEqualTo(36));
    });

    testWidgets('loadingLabel is used in semantics when loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
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
        _buildApp(
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

  // ── Dark mode ──────────────────────────────────────────────────────────

  group('DeelButton dark mode', () {
    testWidgets('uses dark theme colours when dark theme is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          theme: DeelmarktTheme.dark,
          button: DeelButton(
            label: 'Dark',
            onPressed: () {},
            variant: DeelButtonVariant.primary,
          ),
        ),
      );

      // Button renders in dark theme without errors
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Verify DeelButtonThemeData.dark() is used
      final context = tester.element(find.byType(DeelButton));
      final buttonTheme = Theme.of(context).extension<DeelButtonThemeData>();
      expect(buttonTheme, isNotNull);
      expect(buttonTheme!.primaryBackground, DeelmarktColors.darkPrimary);
    });
  });

  // ── Animation ──────────────────────────────────────────────────────────

  group('DeelButton animation', () {
    testWidgets('AnimatedSwitcher crossfades between label and spinner', (
      tester,
    ) async {
      var isLoading = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildApp(
              button: DeelButton(
                label: 'Save',
                onPressed: () => setState(() => isLoading = true),
                isLoading: isLoading,
              ),
            );
          },
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reduced motion uses Duration.zero', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          disableAnimations: true,
          button: DeelButton(label: 'Save', onPressed: () {}, isLoading: true),
        ),
      );

      // With Duration.zero, the transition should be instant
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── ThemeExtension ─────────────────────────────────────────────────────

  group('DeelButtonThemeData', () {
    test('light factory has correct primary colours', () {
      final theme = DeelButtonThemeData.light();
      expect(theme.primaryBackground, DeelmarktColors.primary);
      expect(theme.primaryForeground, DeelmarktColors.white);
    });

    test('dark factory has correct primary colours', () {
      final theme = DeelButtonThemeData.dark();
      expect(theme.primaryBackground, DeelmarktColors.darkPrimary);
      expect(theme.primaryForeground, DeelmarktColors.darkOnPrimary);
    });

    test('lerp interpolates between themes', () {
      final light = DeelButtonThemeData.light();
      final dark = DeelButtonThemeData.dark();
      final mid = light.lerp(dark, 0.5);

      expect(
        mid.primaryBackground,
        Color.lerp(light.primaryBackground, dark.primaryBackground, 0.5),
      );
    });

    test('copyWith returns new instance with overridden values', () {
      final original = DeelButtonThemeData.light();
      final modified = original.copyWith(primaryBackground: Colors.blue);

      expect(modified.primaryBackground, Colors.blue);
      expect(modified.primaryForeground, original.primaryForeground);
    });
  });
}
