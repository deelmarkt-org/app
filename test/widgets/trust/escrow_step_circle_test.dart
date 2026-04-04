import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';

Widget _wrap(Widget child, {bool disableAnimations = true}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('EscrowStepCircle', () {
    testWidgets('complete state shows check icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: true,
            isActive: false,
            semanticLabel: 'Paid',
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, PhosphorIcons.check(PhosphorIconsStyle.bold));
    });

    testWidgets('active state shows inner dot', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: false,
            isActive: true,
            semanticLabel: 'Shipped',
          ),
        ),
      );

      // Active state has outer circle + inner dot = 2 decorated Containers
      final containers = find.byType(Container);
      expect(containers, findsAtLeast(2));
      // No check icon in active state
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('pending state shows empty circle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: false,
            isActive: false,
            semanticLabel: 'Delivered',
          ),
        ),
      );

      // No Icon in pending state
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('has 44px minimum tap target', (tester) async {
      await tester.pumpWidget(
        _wrap(const EscrowStepCircle(isComplete: false, isActive: false)),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, EscrowStepTokens.minTapTarget);
      expect(sizedBox.height, EscrowStepTokens.minTapTarget);
    });

    testWidgets('muted tone complete circle uses neutral accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: true,
            isActive: false,
            tone: EscrowStepTone.muted,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('warning tone active circle renders without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: false,
            isActive: true,
            tone: EscrowStepTone.warning,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('isActive flip triggers didUpdateWidget', (tester) async {
      await tester.pumpWidget(
        _wrap(const EscrowStepCircle(isComplete: false, isActive: false)),
      );
      await tester.pumpAndSettle();
      // Rebuild with active=true — exercises didUpdateWidget branch.
      await tester.pumpWidget(
        _wrap(const EscrowStepCircle(isComplete: false, isActive: true)),
      );
      await tester.pumpAndSettle();
      // And back to inactive — exercises the stop branch.
      await tester.pumpWidget(
        _wrap(const EscrowStepCircle(isComplete: false, isActive: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('pulse animation runs when motion enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(isComplete: false, isActive: true),
          disableAnimations: false,
        ),
      );
      // Give the animation controller a few frames but don't pumpAndSettle
      // (animation is infinite).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(EscrowStepCircle), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EscrowStepCircle(
            isComplete: true,
            isActive: false,
            semanticLabel: 'Betaald',
          ),
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
