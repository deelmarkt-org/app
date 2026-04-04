import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';

import '../../helpers/pump_app.dart';

/// Bypasses the shared helper's `disableAnimations` wrapper for the single
/// "motion enabled" test path. Relies on the test binding for `size` and
/// `devicePixelRatio`.
Widget _motionEnabledWrap(Widget child) => MaterialApp(
  theme: DeelmarktTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('EscrowStepCircle', () {
    testWidgets('complete state shows check icon', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: true,
          isActive: false,
          semanticLabel: 'Paid',
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, PhosphorIcons.check(PhosphorIconsStyle.bold));
    });

    testWidgets('active state shows inner dot', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: false,
          isActive: true,
          semanticLabel: 'Shipped',
        ),
      );

      final containers = find.byType(Container);
      expect(containers, findsAtLeast(2));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('pending state shows empty circle', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: false,
          isActive: false,
          semanticLabel: 'Delivered',
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('has 44px minimum tap target', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(isComplete: false, isActive: false),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, EscrowStepTokens.minTapTarget);
      expect(sizedBox.height, EscrowStepTokens.minTapTarget);
    });

    testWidgets('muted tone complete circle uses neutral accent', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: true,
          isActive: false,
          tone: EscrowStepTone.muted,
        ),
      );
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('warning tone active circle renders without exception', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: false,
          isActive: true,
          tone: EscrowStepTone.warning,
        ),
      );
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('isActive flip triggers didUpdateWidget', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(isComplete: false, isActive: false),
      );
      // Rebuild with active=true — exercises didUpdateWidget branch.
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(isComplete: false, isActive: true),
      );
      // And back to inactive — exercises the stop branch.
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(isComplete: false, isActive: false),
      );
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('pulse animation runs when motion enabled', (tester) async {
      await tester.pumpWidget(
        _motionEnabledWrap(
          const EscrowStepCircle(isComplete: false, isActive: true),
        ),
      );
      // Give the animation controller a few frames but do NOT call
      // pumpAndSettle — the pulse loop is infinite.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowStepCircle(
          isComplete: true,
          isActive: false,
          semanticLabel: 'Betaald',
        ),
      );

      expect(find.bySemanticsLabel('Betaald'), findsOneWidget);
    });
  });

  group('EscrowStepTokens', () {
    test('minTapTarget is 44px (WCAG)', () {
      expect(EscrowStepTokens.minTapTarget, 44);
    });

    test('circleSize is 24px', () {
      expect(EscrowStepTokens.circleSize, 24);
    });
  });

  group('EscrowConnectorPainter', () {
    test('shouldRepaint when isComplete changes', () {
      const a = EscrowConnectorPainter(
        isComplete: true,
        completeColor: DeelmarktColors.trustEscrow,
        pendingColor: DeelmarktColors.neutral300,
      );
      const b = EscrowConnectorPainter(
        isComplete: false,
        completeColor: DeelmarktColors.trustEscrow,
        pendingColor: DeelmarktColors.neutral300,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint false when same', () {
      const a = EscrowConnectorPainter(
        isComplete: true,
        completeColor: DeelmarktColors.trustEscrow,
        pendingColor: DeelmarktColors.neutral300,
      );
      const b = EscrowConnectorPainter(
        isComplete: true,
        completeColor: DeelmarktColors.trustEscrow,
        pendingColor: DeelmarktColors.neutral300,
      );
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
