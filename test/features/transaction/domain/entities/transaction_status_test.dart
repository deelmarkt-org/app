import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';

void main() {
  group('TransactionStatus.isTerminal', () {
    test('released is terminal', () {
      expect(TransactionStatus.released.isTerminal, isTrue);
    });

    test('expired is terminal', () {
      expect(TransactionStatus.expired.isTerminal, isTrue);
    });

    test('failed is terminal', () {
      expect(TransactionStatus.failed.isTerminal, isTrue);
    });

    test('resolved is terminal', () {
      expect(TransactionStatus.resolved.isTerminal, isTrue);
    });

    test('refunded is terminal', () {
      expect(TransactionStatus.refunded.isTerminal, isTrue);
    });

    test('cancelled is terminal', () {
      expect(TransactionStatus.cancelled.isTerminal, isTrue);
    });

    test('created is not terminal', () {
      expect(TransactionStatus.created.isTerminal, isFalse);
    });

    test('paid is not terminal', () {
      expect(TransactionStatus.paid.isTerminal, isFalse);
    });

    test('shipped is not terminal', () {
      expect(TransactionStatus.shipped.isTerminal, isFalse);
    });

    test('delivered is not terminal', () {
      expect(TransactionStatus.delivered.isTerminal, isFalse);
    });

    test('disputed is not terminal', () {
      expect(TransactionStatus.disputed.isTerminal, isFalse);
    });
  });

  group('TransactionStatus.isEscrowHeld', () {
    test('paid holds escrow', () {
      expect(TransactionStatus.paid.isEscrowHeld, isTrue);
    });

    test('shipped holds escrow', () {
      expect(TransactionStatus.shipped.isEscrowHeld, isTrue);
    });

    test('delivered holds escrow', () {
      expect(TransactionStatus.delivered.isEscrowHeld, isTrue);
    });

    test('confirmed holds escrow', () {
      expect(TransactionStatus.confirmed.isEscrowHeld, isTrue);
    });

    test('disputed holds escrow', () {
      expect(TransactionStatus.disputed.isEscrowHeld, isTrue);
    });

    test('created does not hold escrow', () {
      expect(TransactionStatus.created.isEscrowHeld, isFalse);
    });

    test('released does not hold escrow', () {
      expect(TransactionStatus.released.isEscrowHeld, isFalse);
    });
  });

  group('TransactionStatus.validTransitions', () {
    test('created → paymentPending or cancelled', () {
      expect(TransactionStatus.created.validTransitions, {
        TransactionStatus.paymentPending,
        TransactionStatus.cancelled,
      });
    });

    test('paymentPending → paid, expired, failed, cancelled', () {
      expect(TransactionStatus.paymentPending.validTransitions, {
        TransactionStatus.paid,
        TransactionStatus.expired,
        TransactionStatus.failed,
        TransactionStatus.cancelled,
      });
    });

    test('paid → shipped only', () {
      expect(TransactionStatus.paid.validTransitions, {
        TransactionStatus.shipped,
      });
    });

    test('shipped → delivered only', () {
      expect(TransactionStatus.shipped.validTransitions, {
        TransactionStatus.delivered,
      });
    });

    test('delivered → confirmed or disputed', () {
      expect(TransactionStatus.delivered.validTransitions, {
        TransactionStatus.confirmed,
        TransactionStatus.disputed,
      });
    });

    test('confirmed → released only', () {
      expect(TransactionStatus.confirmed.validTransitions, {
        TransactionStatus.released,
      });
    });

    test('disputed → resolved or refunded', () {
      expect(TransactionStatus.disputed.validTransitions, {
        TransactionStatus.resolved,
        TransactionStatus.refunded,
      });
    });

    test('terminal states have no transitions', () {
      for (final status in TransactionStatus.values) {
        if (status.isTerminal) {
          expect(
            status.validTransitions,
            isEmpty,
            reason: '$status should have no valid transitions',
          );
        }
      }
    });
  });

  group('TransactionStatus.canTransitionTo', () {
    test('created can transition to paymentPending', () {
      expect(
        TransactionStatus.created.canTransitionTo(
          TransactionStatus.paymentPending,
        ),
        isTrue,
      );
    });

    test(
      'created cannot transition to paid (must go through paymentPending)',
      () {
        expect(
          TransactionStatus.created.canTransitionTo(TransactionStatus.paid),
          isFalse,
        );
      },
    );

    test('paid cannot transition to released (must go through full flow)', () {
      expect(
        TransactionStatus.paid.canTransitionTo(TransactionStatus.released),
        isFalse,
      );
    });

    test('released cannot transition to anything', () {
      for (final status in TransactionStatus.values) {
        expect(
          TransactionStatus.released.canTransitionTo(status),
          isFalse,
          reason: 'released should not transition to $status',
        );
      }
    });
  });
}
