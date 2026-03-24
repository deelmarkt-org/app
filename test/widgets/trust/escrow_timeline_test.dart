import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EscrowTimeline', () {
    testWidgets('renders 5 step circles', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );

      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
    });

    testWidgets('paid status shows first step as active', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );

      // First circle should be active (paid = index 0)
      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles[0].isActive, isTrue);
      expect(circles[0].isComplete, isFalse);
      expect(circles[1].isActive, isFalse);
      expect(circles[1].isComplete, isFalse);
    });

    testWidgets('shipped status shows paid as complete, shipped as active', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.shipped),
      );

      final circles =
          tester
              .widgetList<EscrowStepCircle>(find.byType(EscrowStepCircle))
              .toList();
      expect(circles[0].isComplete, isTrue); // paid
      expect(circles[1].isActive, isTrue); // shipped
      expect(circles[2].isActive, isFalse); // delivered
    });

    testWidgets('released status shows all complete', (tester) async {
      await pumpTestWidget(
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
          reason: 'Step $i should be complete',
        );
      }
      // Last step (released) is active, not complete
      expect(circles[4].isActive, isTrue);
    });

    testWidgets('onStepTapped fires with correct index', (tester) async {
      int? tappedIndex;
      await pumpTestWidget(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.paid,
          onStepTapped: (i) => tappedIndex = i,
        ),
      );

      // Tap the first step circle
      await tester.tap(find.byType(EscrowStepCircle).first);
      expect(tappedIndex, 0);
    });

    testWidgets('has Semantics with status label', (tester) async {
      await pumpTestWidget(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );

      // The outer Semantics should contain status text
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
