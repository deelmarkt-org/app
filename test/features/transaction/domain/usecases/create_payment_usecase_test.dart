import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/payment_entity.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/exceptions.dart';
import 'package:deelmarkt/features/transaction/domain/usecases/create_payment_usecase.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/payment_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────

class _FakeTransactionRepository implements TransactionRepository {
  TransactionEntity? stubbedTransaction;
  TransactionStatus? lastUpdatedStatus;
  String? lastMolliePaymentId;

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
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  }) async {
    lastMolliePaymentId = molliePaymentId;
    return stubbedTransaction!.copyWith(molliePaymentId: molliePaymentId);
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
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  }) async => throw UnimplementedError();
}

class _FakePaymentRepository implements PaymentRepository {
  PaymentEntity? stubbedPayment;

  @override
  Future<PaymentEntity> createPayment({
    required String transactionId,
    required int amountCents,
    required String currency,
    required String description,
    required String redirectUrl,
    String method = 'ideal',
  }) async => stubbedPayment!;

  @override
  Future<PaymentEntity?> getPayment(String molliePaymentId) async =>
      throw UnimplementedError();

  @override
  Future<List<PaymentEntity>> getPaymentsForTransaction(
    String transactionId,
  ) async => throw UnimplementedError();
}

// ── Helpers ──────────────────────────────────────────────────────────────

TransactionEntity _txn({TransactionStatus status = TransactionStatus.created}) {
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

PaymentEntity _payment() {
  return PaymentEntity(
    id: 'pay_001',
    transactionId: 'txn_001',
    molliePaymentId: 'tr_abc123',
    status: PaymentStatus.open,
    amountCents: 5308,
    currency: 'EUR',
    method: 'ideal',
    createdAt: DateTime(2026, 3, 19),
    checkoutUrl: 'https://mollie.com/checkout/abc',
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late _FakeTransactionRepository txnRepo;
  late _FakePaymentRepository payRepo;
  late CreatePaymentUseCase useCase;

  setUp(() {
    txnRepo = _FakeTransactionRepository();
    payRepo = _FakePaymentRepository();
    useCase = CreatePaymentUseCase(
      transactionRepository: txnRepo,
      paymentRepository: payRepo,
    );
  });

  group('CreatePaymentUseCase', () {
    test('creates payment and transitions to paymentPending', () async {
      txnRepo.stubbedTransaction = _txn();
      payRepo.stubbedPayment = _payment();

      final result = await useCase.execute(
        transactionId: 'txn_001',
        redirectUrl: 'https://deelmarkt.com/payment/success',
      );

      expect(result.molliePaymentId, 'tr_abc123');
      expect(result.checkoutUrl, 'https://mollie.com/checkout/abc');
      expect(txnRepo.lastMolliePaymentId, 'tr_abc123');
      expect(txnRepo.lastUpdatedStatus, TransactionStatus.paymentPending);
    });

    test('throws TransactionNotFoundException when not found', () async {
      txnRepo.stubbedTransaction = null;

      expect(
        () => useCase.execute(
          transactionId: 'txn_missing',
          redirectUrl: 'https://deelmarkt.com/payment/success',
        ),
        throwsA(isA<TransactionNotFoundException>()),
      );
    });

    test('throws InvalidTransitionException from non-created status', () async {
      txnRepo.stubbedTransaction = _txn(status: TransactionStatus.paid);

      expect(
        () => useCase.execute(
          transactionId: 'txn_001',
          redirectUrl: 'https://deelmarkt.com/payment/success',
        ),
        throwsA(isA<InvalidTransitionException>()),
      );
    });
  });
}
