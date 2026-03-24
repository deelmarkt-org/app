import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/ledger_entry.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/exceptions.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/ledger_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:deelmarkt/features/transaction/domain/usecases/confirm_delivery_usecase.dart';

// ── Fakes ────────────────────────────────────────────────────────────────

class _FakeTransactionRepository implements TransactionRepository {
  TransactionEntity? stubbedTransaction;
  TransactionStatus? lastUpdatedStatus;

  @override
  Future<TransactionEntity?> getTransaction(String id) async =>
      stubbedTransaction;

  @override
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  }) async {
    lastUpdatedStatus = newStatus;
    return stubbedTransaction!.copyWith(status: newStatus);
  }

  @override
  Future<TransactionEntity> createTransaction({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  }) async => throw UnimplementedError();

  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async =>
      throw UnimplementedError();

  @override
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  }) async => throw UnimplementedError();

  @override
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  }) async => throw UnimplementedError();
}

class _FakeLedgerRepository implements LedgerRepository {
  final List<({String idempotencyKey, String debit, String credit, int amount})>
  entries = [];

  @override
  Future<LedgerEntry> recordEntry({
    required String transactionId,
    required String idempotencyKey,
    required String debitAccount,
    required String creditAccount,
    required int amountCents,
    String currency = 'EUR',
  }) async {
    entries.add((
      idempotencyKey: idempotencyKey,
      debit: debitAccount,
      credit: creditAccount,
      amount: amountCents,
    ));
    return LedgerEntry(
      id: 'le_${entries.length}',
      transactionId: transactionId,
      idempotencyKey: idempotencyKey,
      debitAccount: debitAccount,
      creditAccount: creditAccount,
      amountCents: amountCents,
      currency: currency,
      createdAt: DateTime(2026, 3, 19),
    );
  }

  @override
  Future<List<LedgerEntry>> getEntriesForTransaction(
    String transactionId,
  ) async => throw UnimplementedError();

  @override
  Future<int> getEscrowBalance(String transactionId) async =>
      throw UnimplementedError();
}

// ── Helpers ──────────────────────────────────────────────────────────────

TransactionEntity _txn({
  TransactionStatus status = TransactionStatus.delivered,
}) {
  return TransactionEntity(
    id: 'txn_001',
    listingId: 'lst_001',
    buyerId: 'usr_buyer',
    sellerId: 'usr_seller',
    status: status,
    itemAmountCents: 4500,
    platformFeeCents: 113,
    shippingCostCents: 695,
    currency: 'EUR',
    createdAt: DateTime(2026, 3, 19),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late _FakeTransactionRepository txnRepo;
  late _FakeLedgerRepository ledgerRepo;
  late ConfirmDeliveryUseCase useCase;

  setUp(() {
    txnRepo = _FakeTransactionRepository();
    ledgerRepo = _FakeLedgerRepository();
    useCase = ConfirmDeliveryUseCase(
      transactionRepository: txnRepo,
      ledgerRepository: ledgerRepo,
    );
  });

  group('ConfirmDeliveryUseCase', () {
    test('records seller payout and confirms', () async {
      // B-20: Platform fee already split at payment time.
      // Confirm delivery only releases seller payout (item + shipping).
      txnRepo.stubbedTransaction = _txn();

      await useCase.execute(transactionId: 'txn_001', sellerId: 'usr_seller');

      expect(ledgerRepo.entries, hasLength(1));

      // Escrow → seller (item + shipping = 5195)
      expect(ledgerRepo.entries[0].debit, 'escrow:txn_001');
      expect(ledgerRepo.entries[0].credit, 'seller:usr_seller');
      expect(ledgerRepo.entries[0].amount, 5195);
      expect(ledgerRepo.entries[0].idempotencyKey, 'release:seller:txn_001');

      expect(txnRepo.lastUpdatedStatus, TransactionStatus.confirmed);
    });

    test('throws TransactionNotFoundException when not found', () async {
      txnRepo.stubbedTransaction = null;

      expect(
        () => useCase.execute(
          transactionId: 'txn_missing',
          sellerId: 'usr_seller',
        ),
        throwsA(isA<TransactionNotFoundException>()),
      );
    });

    test(
      'throws InvalidTransitionException from non-delivered status',
      () async {
        txnRepo.stubbedTransaction = _txn(status: TransactionStatus.paid);

        expect(
          () =>
              useCase.execute(transactionId: 'txn_001', sellerId: 'usr_seller'),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    test('ledger entry has unique idempotency key', () async {
      txnRepo.stubbedTransaction = _txn();

      await useCase.execute(transactionId: 'txn_001', sellerId: 'usr_seller');

      final keys = ledgerRepo.entries.map((e) => e.idempotencyKey).toSet();
      expect(keys, hasLength(1));
    });
  });
}
