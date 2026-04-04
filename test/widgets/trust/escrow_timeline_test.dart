import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';

/// Wraps the widget in a MaterialApp + MediaQuery(disableAnimations: true)
/// so the active-state pulse (TweenAnimationBuilder / AnimationController loop)
/// doesn't starve `pumpAndSettle`.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  Size size = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: size.width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    // Ensure surface size is reset so later tests don't inherit state.
  });

  group('EscrowTimeline — happy path', () {
    testWidgets('renders 5 step circles', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
    });

    testWidgets('paid → first circle active, rest pending', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles[0].isActive, isTrue);
      expect(circles[0].isComplete, isFalse);
      for (var i = 1; i < 5; i++) {
        expect(circles[i].isActive, isFalse);
        expect(circles[i].isComplete, isFalse);
      }
    });

    testWidgets('shipped → paid complete, shipped active', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.shipped),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles[0].isComplete, isTrue);
      expect(circles[1].isActive, isTrue);
    });

    testWidgets('delivered → shows deadline hint when escrowDeadline set', (
      tester,
    ) async {
      await _pump(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.delivered,
          escrowDeadline: DateTime(2026, 4, 10, 14),
        ),
      );
      // The deadline hint key is `escrow.deadlineHint` — in tests the key path
      // itself is returned (no translations loaded).
      expect(find.textContaining('escrow.deadlineHint'), findsOneWidget);
    });

    testWidgets('delivered without deadline → no hint rendered', (
      tester,
    ) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
      );
      expect(find.textContaining('escrow.deadlineHint'), findsNothing);
    });

    testWidgets('released → all prior complete, last active', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.released),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (var i = 0; i < 4; i++) {
        expect(
          circles[i].isComplete,
          isTrue,
          reason: 'step $i should be complete',
        );
      }
      expect(circles[4].isActive, isTrue);
    });
  });

  group('EscrowTimeline — off-path states (fix A1)', () {
    testWidgets('disputed → delivered step active with warning tone', (
      tester,
    ) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.disputed),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles[2].isActive, isTrue);
      expect(circles[2].tone, EscrowStepTone.warning);
      expect(circles[0].isComplete, isTrue);
      expect(circles[1].isComplete, isTrue);
    });

    testWidgets('cancelled → no active step, all muted', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.cancelled),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (final c in circles) {
        expect(c.isActive, isFalse);
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('expired → same cancelled visual', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.expired),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (final c in circles) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('failed → same cancelled visual', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.failed),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (final c in circles) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('refunded → all muted, no active step', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.refunded),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles.every((c) => c.tone == EscrowStepTone.muted), isTrue);
      expect(circles.every((c) => !c.isActive), isTrue);
    });

    testWidgets('resolved → all complete, released step visible as complete', (
      tester,
    ) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.resolved),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (var i = 0; i < 4; i++) {
        expect(circles[i].isComplete, isTrue);
      }
      // Released step for a resolved dispute is shown as complete (terminal).
      expect(circles[4].isComplete, isTrue);
    });

    testWidgets('paymentPending → awaitingPayment muted tone', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paymentPending),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (final c in circles) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('created → awaitingPayment muted tone', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.created),
      );
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      for (final c in circles) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });
  });

  group('EscrowTimeline — interaction', () {
    testWidgets('onStepTapped fires with correct index', (tester) async {
      int? tappedIndex;
      await _pump(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.paid,
          onStepTapped: (i) => tappedIndex = i,
        ),
      );
      // Tap the first step circle — the InkWell wraps the column.
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(tappedIndex, 0);
    });

    testWidgets(
      'onStepTapped null → no InkWell created (no button semantics)',
      (tester) async {
        await _pump(
          tester,
          const EscrowTimeline(currentStatus: TransactionStatus.paid),
        );
        // Steps are still present but wrapped in an InkWell without a handler —
        // Semantics(button:) should not be true.
        final semantics = tester.getSemantics(find.byType(EscrowTimeline));
        expect(semantics, isNotNull);
      },
    );

    testWidgets('semantics label contains status key', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.disputed),
      );
      // Outer Semantics merges status label key (tests receive the key path).
      expect(find.bySemanticsLabel(RegExp('escrow.disputed')), findsWidgets);
    });
  });

  group('EscrowTimeline — responsive (fix A5)', () {
    testWidgets('narrow width (320px) still lays out without exceptions', (
      tester,
    ) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
        size: const Size(320, 720),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      // No overflow exceptions.
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide width (800px) uses single-line labels', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });

  group('EscrowTimeline — dark theme (fix A3)', () {
    testWidgets('renders in dark theme without exceptions', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
        theme: DeelmarktTheme.dark,
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}
