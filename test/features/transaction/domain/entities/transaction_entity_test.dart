import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';

TransactionEntity _createTransaction({
  TransactionStatus status = TransactionStatus.created,
  int itemAmountCents = 4500,
  int platformFeeCents = 113,
  int shippingCostCents = 695,
  DateTime? escrowDeadline,
}) {
  return TransactionEntity(
    id: 'txn_001',
    listingId: 'lst_001',
    buyerId: 'usr_buyer',
    sellerId: 'usr_seller',
    status: status,
    itemAmountCents: itemAmountCents,
    platformFeeCents: platformFeeCents,
    shippingCostCents: shippingCostCents,
    currency: 'EUR',
    createdAt: DateTime(2026, 3, 19),
    escrowDeadline: escrowDeadline,
  );
}

void main() {
  group('TransactionEntity.totalAmountCents', () {
    test('sums item + platformFee + shipping', () {
      final txn = _createTransaction();
      // 4500 + 113 + 695 = 5308
      expect(txn.totalAmountCents, 5308);
    });

    test('handles zero shipping', () {
      final txn = _createTransaction(shippingCostCents: 0);
      expect(txn.totalAmountCents, 4613);
    });
  });

  group('TransactionEntity.sellerPayoutCents', () {
    test('item price + shipping (platform fee paid by buyer on top)', () {
      final txn = _createTransaction();
      // 4500 + 695 = 5195
      expect(txn.sellerPayoutCents, 5195);
    });

    test('handles zero shipping', () {
      final txn = _createTransaction(shippingCostCents: 0);
      expect(txn.sellerPayoutCents, 4500);
    });
  });

  group('TransactionEntity.isEscrowExpired', () {
    test('false when no deadline set', () {
      final txn = _createTransaction();
      expect(txn.isEscrowExpired(), isFalse);
    });

    test('false when deadline is in the future', () {
      final deadline = DateTime(2026, 4);
      final txn = _createTransaction(escrowDeadline: deadline);
      expect(txn.isEscrowExpired(now: DateTime(2026, 3, 30)), isFalse);
    });

    test('true when deadline has passed', () {
      final deadline = DateTime(2026, 3, 15);
      final txn = _createTransaction(escrowDeadline: deadline);
      expect(txn.isEscrowExpired(now: DateTime(2026, 3, 20)), isTrue);
    });
  });

  group('TransactionEntity.copyWith', () {
    test('updates status', () {
      final txn = _createTransaction();
      final updated = txn.copyWith(status: TransactionStatus.paid);
      expect(updated.status, TransactionStatus.paid);
      expect(updated.id, txn.id);
      expect(updated.itemAmountCents, txn.itemAmountCents);
    });

    test('updates molliePaymentId', () {
      final txn = _createTransaction();
      final updated = txn.copyWith(molliePaymentId: 'tr_abc123');
      expect(updated.molliePaymentId, 'tr_abc123');
    });

    test('preserves existing fields when not overridden', () {
      final txn = _createTransaction(
        status: TransactionStatus.paid,
      ).copyWith(molliePaymentId: 'tr_xyz');
      expect(txn.status, TransactionStatus.paid);
      expect(txn.molliePaymentId, 'tr_xyz');
      expect(txn.buyerId, 'usr_buyer');
    });
  });

  group('TransactionEntity equality', () {
    test('equal when same id', () {
      final a = _createTransaction();
      final b = _createTransaction(itemAmountCents: 9999);
      expect(a, equals(b));
    });

    test('hashCode based on id', () {
      final a = _createTransaction();
      final b = _createTransaction();
      expect(a.hashCode, b.hashCode);
    });
  });
}
