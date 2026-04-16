import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';

void main() {
  group('TransactionStatus', () {
    group('toDb', () {
      test('converts paymentPending to payment_pending', () {
        expect(TransactionStatus.paymentPending.toDb(), 'payment_pending');
      });

      test('converts simple statuses using enum name', () {
        expect(TransactionStatus.created.toDb(), 'created');
        expect(TransactionStatus.paid.toDb(), 'paid');
        expect(TransactionStatus.shipped.toDb(), 'shipped');
        expect(TransactionStatus.delivered.toDb(), 'delivered');
        expect(TransactionStatus.confirmed.toDb(), 'confirmed');
        expect(TransactionStatus.released.toDb(), 'released');
        expect(TransactionStatus.expired.toDb(), 'expired');
        expect(TransactionStatus.failed.toDb(), 'failed');
        expect(TransactionStatus.disputed.toDb(), 'disputed');
        expect(TransactionStatus.resolved.toDb(), 'resolved');
        expect(TransactionStatus.refunded.toDb(), 'refunded');
        expect(TransactionStatus.cancelled.toDb(), 'cancelled');
      });
    });

    group('fromDb', () {
      test('parses all valid DB values', () {
        expect(TransactionStatus.fromDb('created'), TransactionStatus.created);
        expect(
          TransactionStatus.fromDb('payment_pending'),
          TransactionStatus.paymentPending,
        );
        expect(TransactionStatus.fromDb('paid'), TransactionStatus.paid);
        expect(TransactionStatus.fromDb('shipped'), TransactionStatus.shipped);
        expect(
          TransactionStatus.fromDb('delivered'),
          TransactionStatus.delivered,
        );
        expect(
          TransactionStatus.fromDb('confirmed'),
          TransactionStatus.confirmed,
        );
        expect(
          TransactionStatus.fromDb('released'),
          TransactionStatus.released,
        );
        expect(TransactionStatus.fromDb('expired'), TransactionStatus.expired);
        expect(TransactionStatus.fromDb('failed'), TransactionStatus.failed);
        expect(
          TransactionStatus.fromDb('disputed'),
          TransactionStatus.disputed,
        );
        expect(
          TransactionStatus.fromDb('resolved'),
          TransactionStatus.resolved,
        );
        expect(
          TransactionStatus.fromDb('refunded'),
          TransactionStatus.refunded,
        );
        expect(
          TransactionStatus.fromDb('cancelled'),
          TransactionStatus.cancelled,
        );
      });

      test('defaults unknown values to created', () {
        expect(
          TransactionStatus.fromDb('unknown_future_status'),
          TransactionStatus.created,
        );
      });
    });

    group('round-trip', () {
      test('fromDb(toDb(status)) == status for all values', () {
        for (final status in TransactionStatus.values) {
          expect(
            TransactionStatus.fromDb(status.toDb()),
            status,
            reason: '${status.name} round-trip failed',
          );
        }
      });
    });
  });
}
