import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/transaction/domain/entities/ledger_entry.dart';

void main() {
  group('LedgerAccounts', () {
    test('buyer account format', () {
      expect(LedgerAccounts.buyer('usr_123'), 'buyer:usr_123');
    });

    test('seller account format', () {
      expect(LedgerAccounts.seller('usr_456'), 'seller:usr_456');
    });

    test('escrow account format', () {
      expect(LedgerAccounts.escrow('txn_789'), 'escrow:txn_789');
    });

    test('platform account is constant', () {
      expect(LedgerAccounts.platform, 'platform:commission');
    });
  });

  group('LedgerEntry', () {
    test('can be created with required fields', () {
      final entry = LedgerEntry(
        id: 'le_001',
        transactionId: 'txn_001',
        idempotencyKey: 'payment:txn_001',
        debitAccount: LedgerAccounts.buyer('usr_buyer'),
        creditAccount: LedgerAccounts.escrow('txn_001'),
        amountCents: 5308,
        currency: 'EUR',
        createdAt: DateTime(2026, 3, 19),
      );

      expect(entry.id, 'le_001');
      expect(entry.transactionId, 'txn_001');
      expect(entry.idempotencyKey, 'payment:txn_001');
      expect(entry.debitAccount, 'buyer:usr_buyer');
      expect(entry.creditAccount, 'escrow:txn_001');
      expect(entry.amountCents, 5308);
      expect(entry.currency, 'EUR');
    });

    test('equal when same id', () {
      final a = LedgerEntry(
        id: 'le_001',
        transactionId: 'txn_001',
        idempotencyKey: 'key_a',
        debitAccount: 'buyer:usr_1',
        creditAccount: 'escrow:txn_001',
        amountCents: 5308,
        currency: 'EUR',
        createdAt: DateTime(2026, 3, 19),
      );
      final b = LedgerEntry(
        id: 'le_001',
        transactionId: 'txn_002',
        idempotencyKey: 'key_b',
        debitAccount: 'escrow:txn_002',
        creditAccount: 'seller:usr_2',
        amountCents: 9999,
        currency: 'EUR',
        createdAt: DateTime(2026, 3, 20),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
