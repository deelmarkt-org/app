import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/ledger_entry.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/exceptions.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/ledger_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:deelmarkt/features/transaction/domain/usecases/record_escrow_deposit_usecase.dart';

class _FakeTransactionRepo implements TransactionRepository {
  TransactionEntity? stubbedTransaction;

  @override
  Future<TransactionEntity?> getTransaction(String id) async =>
      stubbedTransaction;

  @override
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  }) async => throw UnimplementedError();

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

class _FakeLedgerRepo implements LedgerRepository {
  final List<({String key, String debit, String credit, int amount})> entries =
      [];

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
      key: idempotencyKey,
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

TransactionEntity _txn({TransactionStatus status = TransactionStatus.paid}) {
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

void main() {
  late _FakeTransactionRepo txnRepo;
  late _FakeLedgerRepo ledgerRepo;
  late RecordEscrowDepositUseCase useCase;

  setUp(() {
    txnRepo = _FakeTransactionRepo();
    ledgerRepo = _FakeLedgerRepo();
    useCase = RecordEscrowDepositUseCase(
      transactionRepository: txnRepo,
      ledgerRepository: ledgerRepo,
    );
  });

  group('RecordEscrowDepositUseCase', () {
    test('records buyer→escrow entry for totalAmountCents', () async {
      txnRepo.stubbedTransaction = _txn();

      await useCase.execute(transactionId: 'txn_001', buyerId: 'usr_buyer');

      expect(ledgerRepo.entries, hasLength(1));
      expect(ledgerRepo.entries[0].debit, 'buyer:usr_buyer');
      expect(ledgerRepo.entries[0].credit, 'escrow:txn_001');
      // totalAmountCents = 4500 + 113 + 695 = 5308
      expect(ledgerRepo.entries[0].amount, 5308);
    });

    test('throws TransactionNotFoundException when not found', () async {
      txnRepo.stubbedTransaction = null;

      expect(
        () => useCase.execute(transactionId: 'txn_missing', buyerId: 'usr_x'),
        throwsA(isA<TransactionNotFoundException>()),
      );
    });

    test('throws InvalidTransitionException when not in paid status', () async {
      txnRepo.stubbedTransaction = _txn(status: TransactionStatus.created);

      expect(
        () => useCase.execute(transactionId: 'txn_001', buyerId: 'usr_buyer'),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test('idempotency key includes transactionId', () async {
      txnRepo.stubbedTransaction = _txn();

      await useCase.execute(transactionId: 'txn_001', buyerId: 'usr_buyer');

      expect(ledgerRepo.entries[0].key, contains('txn_001'));
    });
  });
}
