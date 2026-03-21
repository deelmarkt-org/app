import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/transaction/domain/entities/payment_entity.dart';

void main() {
  group('PaymentStatus.isSuccessful', () {
    test('paid is successful', () {
      expect(PaymentStatus.paid.isSuccessful, isTrue);
    });

    test('open is not successful', () {
      expect(PaymentStatus.open.isSuccessful, isFalse);
    });

    test('failed is not successful', () {
      expect(PaymentStatus.failed.isSuccessful, isFalse);
    });
  });

  group('PaymentStatus.isFailed', () {
    test('expired is failed', () {
      expect(PaymentStatus.expired.isFailed, isTrue);
    });

    test('failed is failed', () {
      expect(PaymentStatus.failed.isFailed, isTrue);
    });

    test('canceled is failed', () {
      expect(PaymentStatus.canceled.isFailed, isTrue);
    });

    test('paid is not failed', () {
      expect(PaymentStatus.paid.isFailed, isFalse);
    });

    test('open is not failed', () {
      expect(PaymentStatus.open.isFailed, isFalse);
    });
  });

  group('PaymentStatus.isPending', () {
    test('open is pending', () {
      expect(PaymentStatus.open.isPending, isTrue);
    });

    test('pending is pending', () {
      expect(PaymentStatus.pending.isPending, isTrue);
    });

    test('authorized is pending', () {
      expect(PaymentStatus.authorized.isPending, isTrue);
    });

    test('paid is not pending', () {
      expect(PaymentStatus.paid.isPending, isFalse);
    });

    test('expired is not pending', () {
      expect(PaymentStatus.expired.isPending, isFalse);
    });
  });

  group('PaymentStatus coverage — all values categorised', () {
    test('every status is either pending, successful, or failed', () {
      for (final status in PaymentStatus.values) {
        final categorised =
            status.isPending || status.isSuccessful || status.isFailed;
        expect(
          categorised,
          isTrue,
          reason: '$status must be pending, successful, or failed',
        );
      }
    });

    test('no status is both successful and failed', () {
      for (final status in PaymentStatus.values) {
        if (status.isSuccessful) {
          expect(
            status.isFailed,
            isFalse,
            reason: '$status cannot be both successful and failed',
          );
        }
      }
    });
  });

  group('PaymentEntity equality', () {
    test('equal when same id', () {
      final a = PaymentEntity(
        id: 'pay_001',
        transactionId: 'txn_001',
        molliePaymentId: 'tr_abc',
        status: PaymentStatus.open,
        amountCents: 5308,
        currency: 'EUR',
        method: 'ideal',
        createdAt: DateTime(2026, 3, 19),
      );
      final b = PaymentEntity(
        id: 'pay_001',
        transactionId: 'txn_002',
        molliePaymentId: 'tr_xyz',
        status: PaymentStatus.paid,
        amountCents: 9999,
        currency: 'EUR',
        method: 'creditcard',
        createdAt: DateTime(2026, 3, 20),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when different id', () {
      final a = PaymentEntity(
        id: 'pay_001',
        transactionId: 'txn_001',
        molliePaymentId: 'tr_abc',
        status: PaymentStatus.open,
        amountCents: 5308,
        currency: 'EUR',
        method: 'ideal',
        createdAt: DateTime(2026, 3, 19),
      );
      final b = PaymentEntity(
        id: 'pay_002',
        transactionId: 'txn_001',
        molliePaymentId: 'tr_abc',
        status: PaymentStatus.open,
        amountCents: 5308,
        currency: 'EUR',
        method: 'ideal',
        createdAt: DateTime(2026, 3, 19),
      );
      expect(a, isNot(equals(b)));
    });
  });
}
