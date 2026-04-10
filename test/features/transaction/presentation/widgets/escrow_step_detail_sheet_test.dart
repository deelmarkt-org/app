import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/escrow_step_detail_sheet.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline_state.dart';

import '../../../../helpers/pump_app.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TransactionEntity _txn({
  DateTime? paidAt,
  DateTime? shippedAt,
  DateTime? deliveredAt,
  DateTime? confirmedAt,
  DateTime? releasedAt,
  DateTime? disputedAt,
  DateTime? escrowDeadline,
  TransactionStatus status = TransactionStatus.paid,
}) {
  return TransactionEntity(
    id: 'txn_test',
    listingId: 'lst_test',
    buyerId: 'usr_buyer',
    sellerId: 'usr_seller',
    status: status,
    itemAmountCents: 4500,
    platformFeeCents: 113,
    shippingCostCents: 695,
    currency: 'EUR',
    createdAt: DateTime(2026, 3, 19),
    paidAt: paidAt,
    shippedAt: shippedAt,
    deliveredAt: deliveredAt,
    confirmedAt: confirmedAt,
    releasedAt: releasedAt,
    disputedAt: disputedAt,
    escrowDeadline: escrowDeadline,
  );
}

/// Pumps a button that opens [EscrowStepDetailSheet] via the static show().
/// Lets us test the modal opening + content end-to-end.
Future<void> pumpSheetOpener(
  WidgetTester tester,
  TransactionEntity transaction,
  EscrowTimelineStep step, {
  ThemeData? theme,
}) async {
  await pumpTestWidget(
    tester,
    Builder(
      builder:
          (ctx) => TextButton(
            onPressed:
                () => EscrowStepDetailSheet.show(
                  ctx,
                  step: step,
                  transaction: transaction,
                ),
            child: const Text('open'),
          ),
    ),
    theme: theme,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EscrowStepDetailSheet', () {
    // -------------------------------------------------------------------------
    // 1. Sheet opens via static show()
    // -------------------------------------------------------------------------
    testWidgets('opens via show() factory', (tester) async {
      await pumpSheetOpener(tester, _txn(), EscrowTimelineStep.paid);
      expect(find.byType(EscrowStepDetailSheet), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. Displays correct step name for each of the 5 steps
    // -------------------------------------------------------------------------
    for (final (step, l10nKey) in [
      (EscrowTimelineStep.paid, 'escrow.paid'),
      (EscrowTimelineStep.shipped, 'escrow.shipped'),
      (EscrowTimelineStep.delivered, 'escrow.delivered'),
      (EscrowTimelineStep.confirmed, 'escrow.confirmed'),
      (EscrowTimelineStep.released, 'escrow.released'),
    ]) {
      testWidgets('shows step name for $step ($l10nKey)', (tester) async {
        await pumpSheetOpener(tester, _txn(), step);
        expect(find.text(l10nKey), findsOneWidget);
      });
    }

    // -------------------------------------------------------------------------
    // 3. Shows formatted timestamp when present
    // -------------------------------------------------------------------------
    testWidgets('shows formatted paidAt timestamp', (tester) async {
      final paidAt = DateTime(2026, 3, 19, 14, 30);
      await pumpSheetOpener(
        tester,
        _txn(paidAt: paidAt),
        EscrowTimelineStep.paid,
      );

      expect(find.text('escrow.stepDetail.completedAt'), findsOneWidget);
      expect(
        find.textContaining(Formatters.shortDateTime(paidAt)),
        findsOneWidget,
      );
    });

    // -------------------------------------------------------------------------
    // 4. Shows "not reached" when timestamp is null
    // -------------------------------------------------------------------------
    testWidgets('shows not-reached text when timestamp is null', (
      tester,
    ) async {
      // confirmedAt is null by default
      await pumpSheetOpener(tester, _txn(), EscrowTimelineStep.confirmed);
      expect(find.text('escrow.stepDetail.notReached'), findsOneWidget);
      expect(find.text('escrow.stepDetail.completedAt'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 5. Shows escrow deadline row for the delivered step
    // -------------------------------------------------------------------------
    testWidgets('shows escrow deadline row for delivered step', (tester) async {
      final deadline = DateTime(2026, 3, 21, 10);
      await pumpSheetOpener(
        tester,
        _txn(
          deliveredAt: DateTime(2026, 3, 19, 16),
          escrowDeadline: deadline,
          status: TransactionStatus.delivered,
        ),
        EscrowTimelineStep.delivered,
      );

      expect(find.text('escrow.stepDetail.deadline'), findsOneWidget);
      expect(
        find.textContaining(Formatters.shortDateTime(deadline)),
        findsWidgets,
      );
    });

    // -------------------------------------------------------------------------
    // 6. Shows disputedAt row when set on the delivered step
    // -------------------------------------------------------------------------
    testWidgets('shows disputedAt row for delivered step', (tester) async {
      final disputedAt = DateTime(2026, 3, 20, 9, 15);
      await pumpSheetOpener(
        tester,
        _txn(
          deliveredAt: DateTime(2026, 3, 19, 16),
          disputedAt: disputedAt,
          status: TransactionStatus.disputed,
        ),
        EscrowTimelineStep.delivered,
      );

      expect(find.text('escrow.stepDetail.disputedAt'), findsOneWidget);
      expect(
        find.textContaining(Formatters.shortDateTime(disputedAt)),
        findsWidgets,
      );
    });

    // -------------------------------------------------------------------------
    // 7. Deadline row does NOT appear for non-delivered steps
    // -------------------------------------------------------------------------
    testWidgets('deadline row not shown for non-delivered steps', (
      tester,
    ) async {
      final deadline = DateTime(2026, 3, 21, 10);
      // paid step — escrowDeadline is set but should not be shown
      await pumpSheetOpener(
        tester,
        _txn(escrowDeadline: deadline),
        EscrowTimelineStep.paid,
      );
      expect(find.text('escrow.stepDetail.deadline'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 8. Sheet renders with M3 drag handle (showDragHandle: true)
    // -------------------------------------------------------------------------
    testWidgets('sheet uses built-in M3 drag handle via show()', (
      tester,
    ) async {
      // The drag handle is now Flutter's built-in (showDragHandle: true).
      // Verify the sheet opens and renders the step name — no manual Container.
      await pumpSheetOpener(
        tester,
        _txn(paidAt: DateTime(2026, 3, 19, 14, 30)),
        EscrowTimelineStep.paid,
      );
      expect(find.byType(EscrowStepDetailSheet), findsOneWidget);
      expect(find.text('escrow.paid'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 9. Semantics header wraps step name
    // -------------------------------------------------------------------------
    testWidgets('step name has Semantics header', (tester) async {
      await pumpTestWidget(
        tester,
        EscrowStepDetailSheet(
          step: EscrowTimelineStep.paid,
          transaction: _txn(),
        ),
      );

      final semanticsNodes = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final headerNode = semanticsNodes.firstWhere(
        (s) => s.properties.header == true,
        orElse: () => Semantics(),
      );
      expect(headerNode.properties.header, isTrue);
    });

    // -------------------------------------------------------------------------
    // 10. Dark mode renders without errors
    // -------------------------------------------------------------------------
    testWidgets('renders correctly in dark mode', (tester) async {
      await pumpTestWidget(
        tester,
        EscrowStepDetailSheet(
          step: EscrowTimelineStep.paid,
          transaction: _txn(paidAt: DateTime(2026, 3, 19, 14, 30)),
        ),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(EscrowStepDetailSheet), findsOneWidget);
      // Primary orange deadline color should not appear (paid step, no deadline)
      final deadlineText = find.text('escrow.stepDetail.deadline');
      expect(deadlineText, findsNothing);
    });
  });
}
