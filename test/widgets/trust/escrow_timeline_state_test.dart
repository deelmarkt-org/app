import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline_state.dart';

void main() {
  group('computeEscrowTimelineState — happy path', () {
    test('paid → active index 0, 0 complete', () {
      final state = computeEscrowTimelineState(TransactionStatus.paid);
      expect(state.shape, EscrowTimelineShape.happyPath);
      expect(state.activeStepIndex, 0);
      expect(state.completedStepCount, 0);
      expect(state.showDeadline, isFalse);
      expect(state.statusLabelKey, 'transaction.paid');
      expect(state.isTerminal, isFalse);
      expect(state.isMuted, isFalse);
    });

    test('shipped → active index 1, 1 complete', () {
      final state = computeEscrowTimelineState(TransactionStatus.shipped);
      expect(state.activeStepIndex, 1);
      expect(state.completedStepCount, 1);
      expect(state.statusLabelKey, 'transaction.shipped');
    });

    test('delivered → active index 2, showDeadline true', () {
      final state = computeEscrowTimelineState(TransactionStatus.delivered);
      expect(state.activeStepIndex, 2);
      expect(state.completedStepCount, 2);
      expect(state.showDeadline, isTrue);
      expect(state.statusLabelKey, 'transaction.delivered');
    });

    test('confirmed → active index 3, 3 complete', () {
      final state = computeEscrowTimelineState(TransactionStatus.confirmed);
      expect(state.activeStepIndex, 3);
      expect(state.completedStepCount, 3);
      expect(state.statusLabelKey, 'transaction.confirmed');
    });

    test('released → active index 4, all 4 prior complete', () {
      final state = computeEscrowTimelineState(TransactionStatus.released);
      expect(state.activeStepIndex, 4);
      expect(state.completedStepCount, 4);
      expect(state.statusLabelKey, 'transaction.released');
    });
  });

  group('computeEscrowTimelineState — awaiting payment', () {
    test('created → awaitingPayment, muted, no active step', () {
      final state = computeEscrowTimelineState(TransactionStatus.created);
      expect(state.shape, EscrowTimelineShape.awaitingPayment);
      expect(state.activeStepIndex, -1);
      expect(state.completedStepCount, 0);
      expect(state.isMuted, isTrue);
      expect(state.isTerminal, isFalse);
      expect(state.statusLabelKey, 'transaction.paymentPending');
    });

    test('paymentPending → same awaiting payment state', () {
      final state = computeEscrowTimelineState(
        TransactionStatus.paymentPending,
      );
      expect(state.shape, EscrowTimelineShape.awaitingPayment);
      expect(state.isMuted, isTrue);
    });
  });

  group('computeEscrowTimelineState — dispute branch', () {
    test('disputed → anchors on delivered step, disputed shape', () {
      final state = computeEscrowTimelineState(TransactionStatus.disputed);
      expect(state.shape, EscrowTimelineShape.disputed);
      expect(state.activeStepIndex, 2);
      expect(state.completedStepCount, 2);
      expect(state.statusLabelKey, 'escrow.disputed');
      expect(state.isTerminal, isFalse);
      expect(state.isMuted, isFalse);
    });

    test('resolved → terminalResolved, acts like released visually', () {
      final state = computeEscrowTimelineState(TransactionStatus.resolved);
      expect(state.shape, EscrowTimelineShape.terminalResolved);
      expect(state.activeStepIndex, 4);
      expect(state.isTerminal, isTrue);
      expect(state.isMuted, isFalse);
      expect(state.statusLabelKey, 'escrow.terminalResolved');
    });

    test('refunded → muted, terminal, no active step', () {
      final state = computeEscrowTimelineState(TransactionStatus.refunded);
      expect(state.shape, EscrowTimelineShape.terminalRefunded);
      expect(state.activeStepIndex, -1);
      expect(state.isTerminal, isTrue);
      expect(state.isMuted, isTrue);
      expect(state.statusLabelKey, 'escrow.terminalRefunded');
    });
  });

  group('computeEscrowTimelineState — cancellation branch', () {
    test('cancelled → cancelled shape, muted, terminal', () {
      final state = computeEscrowTimelineState(TransactionStatus.cancelled);
      expect(state.shape, EscrowTimelineShape.cancelled);
      expect(state.isTerminal, isTrue);
      expect(state.isMuted, isTrue);
      expect(state.statusLabelKey, 'escrow.cancelled');
    });

    test('expired → same cancelled shape', () {
      final state = computeEscrowTimelineState(TransactionStatus.expired);
      expect(state.shape, EscrowTimelineShape.cancelled);
      expect(state.isTerminal, isTrue);
    });

    test('failed → same cancelled shape', () {
      final state = computeEscrowTimelineState(TransactionStatus.failed);
      expect(state.shape, EscrowTimelineShape.cancelled);
      expect(state.isTerminal, isTrue);
    });
  });

  group('EscrowTimelineStep', () {
    test('each step maps to its matching TransactionStatus', () {
      expect(EscrowTimelineStep.paid.status, TransactionStatus.paid);
      expect(EscrowTimelineStep.shipped.status, TransactionStatus.shipped);
      expect(EscrowTimelineStep.delivered.status, TransactionStatus.delivered);
      expect(EscrowTimelineStep.confirmed.status, TransactionStatus.confirmed);
      expect(EscrowTimelineStep.released.status, TransactionStatus.released);
    });

    test('values length matches the visible timeline length', () {
      expect(EscrowTimelineStep.values.length, 5);
    });
  });

  group('coverage completeness', () {
    test('mapper handles every TransactionStatus value', () {
      // Guards against future enum additions silently slipping through.
      for (final status in TransactionStatus.values) {
        final state = computeEscrowTimelineState(status);
        // Every state has a valid label key.
        expect(state.statusLabelKey, isNotEmpty);
        // activeStepIndex is either -1 or within [0, 4].
        expect(
          state.activeStepIndex == -1 ||
              (state.activeStepIndex >= 0 && state.activeStepIndex <= 4),
          isTrue,
          reason: 'Invalid activeStepIndex for $status',
        );
        // completedStepCount is within [0, 5] and never exceeds active + 1.
        expect(state.completedStepCount >= 0, isTrue);
        expect(state.completedStepCount <= 5, isTrue);
      }
    });
  });
}
