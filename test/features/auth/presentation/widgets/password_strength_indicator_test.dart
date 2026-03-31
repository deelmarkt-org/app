import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/utils/validators.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labels = ['Weak', 'Fair', 'Strong', 'Very strong'];

  Widget buildSubject({required PasswordStrength strength}) {
    return MaterialApp(
      home: Scaffold(
        body: PasswordStrengthIndicator(strength: strength, labels: labels),
      ),
    );
  }

  group('PasswordStrengthIndicator', () {
    group('displays correct label for each strength level', () {
      testWidgets('weak', (tester) async {
        await tester.pumpWidget(buildSubject(strength: PasswordStrength.weak));
        await tester.pumpAndSettle();

        expect(find.text('Weak'), findsOneWidget);
      });

      testWidgets('fair', (tester) async {
        await tester.pumpWidget(buildSubject(strength: PasswordStrength.fair));
        await tester.pumpAndSettle();

        expect(find.text('Fair'), findsOneWidget);
      });

      testWidgets('strong', (tester) async {
        await tester.pumpWidget(
          buildSubject(strength: PasswordStrength.strong),
        );
        await tester.pumpAndSettle();

        expect(find.text('Strong'), findsOneWidget);
      });

      testWidgets('veryStrong', (tester) async {
        await tester.pumpWidget(
          buildSubject(strength: PasswordStrength.veryStrong),
        );
        await tester.pumpAndSettle();

        expect(find.text('Very strong'), findsOneWidget);
      });
    });

    group('shows correct number of filled segments', () {
      testWidgets('weak has 1 filled segment', (tester) async {
        await tester.pumpWidget(buildSubject(strength: PasswordStrength.weak));
        await tester.pumpAndSettle();

        final containers = _findAnimatedContainers(tester);
        expect(containers, hasLength(4));

        final filledCount =
            containers
                .where((c) => _decorationColor(c) == DeelmarktColors.error)
                .length;
        expect(filledCount, 1);
      });

      testWidgets('fair has 2 filled segments', (tester) async {
        await tester.pumpWidget(buildSubject(strength: PasswordStrength.fair));
        await tester.pumpAndSettle();

        final containers = _findAnimatedContainers(tester);
        final filledCount =
            containers
                .where((c) => _decorationColor(c) == DeelmarktColors.warning)
                .length;
        expect(filledCount, 2);
      });

      testWidgets('strong has 3 filled segments', (tester) async {
        await tester.pumpWidget(
          buildSubject(strength: PasswordStrength.strong),
        );
        await tester.pumpAndSettle();

        final containers = _findAnimatedContainers(tester);
        final filledCount =
            containers
                .where((c) => _decorationColor(c) == DeelmarktColors.success)
                .length;
        expect(filledCount, 3);
      });

      testWidgets('veryStrong has 4 filled segments', (tester) async {
        await tester.pumpWidget(
          buildSubject(strength: PasswordStrength.veryStrong),
        );
        await tester.pumpAndSettle();

        final containers = _findAnimatedContainers(tester);
        final filledCount =
            containers
                .where((c) => _decorationColor(c) == DeelmarktColors.success)
                .length;
        expect(filledCount, 4);
      });
    });

    testWidgets('has Semantics liveRegion', (tester) async {
      await tester.pumpWidget(buildSubject(strength: PasswordStrength.strong));
      await tester.pumpAndSettle();

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(semantics, isNotNull);
      expect(semantics.properties.label, 'Strong');
    });
  });
}

/// Finds all [AnimatedContainer] widgets rendered by the indicator segments.
List<AnimatedContainer> _findAnimatedContainers(WidgetTester tester) {
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .toList();
}

/// Extracts the background [Color] from an [AnimatedContainer]'s [BoxDecoration].
Color? _decorationColor(AnimatedContainer container) {
  final decoration = container.decoration;
  if (decoration is BoxDecoration) {
    return decoration.color;
  }
  return null;
}
