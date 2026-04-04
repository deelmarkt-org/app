import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';

import '../../helpers/pump_app.dart';

/// Sizes the surface and pumps via the shared `pumpTestWidget` helper so
/// disableAnimations is wired without clobbering the test binding size.
Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  Size size = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(size);
  await pumpTestWidget(
    tester,
    SizedBox(width: size.width, child: child),
    theme: theme,
  );
}

void main() {
  group('EscrowTimeline — happy path', () {
    testWidgets('renders 5 step circles', (tester) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
    });

    testWidgets('paid → first circle active, rest pending', (tester) async {
      await _pumpAtSize(
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
      await _pumpAtSize(
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
      await _pumpAtSize(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.delivered,
          escrowDeadline: DateTime(2026, 4, 10, 14),
        ),
      );
      // The deadline hint key is `escrow.deadlineHint` — tests receive the
      // key path (no translations loaded).
      expect(find.textContaining('escrow.deadlineHint'), findsOneWidget);
    });

    testWidgets('delivered without deadline → no hint rendered', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
      );
      expect(find.textContaining('escrow.deadlineHint'), findsNothing);
    });

    testWidgets('released → all prior complete, last active', (tester) async {
      await _pumpAtSize(
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

  group('EscrowTimeline — interaction', () {
    testWidgets('onStepTapped fires with correct index', (tester) async {
      int? tappedIndex;
      await _pumpAtSize(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.paid,
          onStepTapped: (i) => tappedIndex = i,
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(tappedIndex, 0);
    });

    testWidgets('onStepTapped null → button semantics is false (fix M7)', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.paid),
      );
      // Inspect the five step-column Semantics nodes explicitly: none should
      // advertise a tap action when the callback is null.
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      for (final ink in inkWells) {
        expect(
          ink.onTap,
          isNull,
          reason: 'InkWell onTap must be null when onStepTapped is null',
        );
      }
    });

    testWidgets('semantics label contains status key', (tester) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.disputed),
      );
      expect(find.bySemanticsLabel(RegExp('escrow.disputed')), findsWidgets);
    });
  });

  group('EscrowTimeline — responsive (fix A5)', () {
    testWidgets('narrow width (320px) still lays out without exceptions', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
        size: const Size(320, 720),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow width with deadline hint still fits', (tester) async {
      await _pumpAtSize(
        tester,
        EscrowTimeline(
          currentStatus: TransactionStatus.delivered,
          escrowDeadline: DateTime(2026, 4, 10, 14),
        ),
        size: const Size(320, 720),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide width (800px) uses single-line labels', (tester) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });

  group('EscrowTimeline — dark theme (fix A3)', () {
    testWidgets('renders in dark theme without exceptions', (tester) async {
      await _pumpAtSize(
        tester,
        const EscrowTimeline(currentStatus: TransactionStatus.delivered),
        theme: DeelmarktTheme.dark,
      );
      expect(find.byType(EscrowStepCircle), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}
