import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';

import '../../helpers/pump_app.dart';

/// Fix A1: TransactionStatus values that previously rendered the entire
/// timeline as "pending" now have explicit visual states. This suite asserts
/// every off-path branch reached by `computeEscrowTimelineState`.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(800, 600));
  await pumpTestWidget(
    tester,
    const SizedBox(width: 800, child: SizedBox.shrink()),
  );
  // Re-pump with the real widget after the size is primed.
  await pumpTestWidget(tester, SizedBox(width: 800, child: child));
}

List<EscrowStepCircle> _circles(WidgetTester tester) =>
    tester.widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle)).toList();

void main() {
  group('EscrowTimeline — off-path states (fix A1)', () {
    testWidgets('disputed → delivered step active with warning tone', (
      tester,
    ) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.disputed),
      );
      final circles = _circles(tester);
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
      for (final c in _circles(tester)) {
        expect(c.isActive, isFalse);
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('expired → same cancelled visual', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.expired),
      );
      for (final c in _circles(tester)) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('failed → same cancelled visual', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.failed),
      );
      for (final c in _circles(tester)) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('refunded → all muted, no active step', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.refunded),
      );
      final circles = _circles(tester);
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
      final circles = _circles(tester);
      for (var i = 0; i < 4; i++) {
        expect(circles[i].isComplete, isTrue);
      }
      expect(circles[4].isComplete, isTrue);
    });

    testWidgets('paymentPending → awaitingPayment muted tone', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paymentPending),
      );
      for (final c in _circles(tester)) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });

    testWidgets('created → awaitingPayment muted tone', (tester) async {
      await _pump(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.created),
      );
      for (final c in _circles(tester)) {
        expect(c.tone, EscrowStepTone.muted);
      }
    });
  });
}
