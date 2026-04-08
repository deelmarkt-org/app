import 'package:flutter/foundation.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

/// In-memory mock for development when Supabase transactions table isn't ready.
///
/// Returns hardcoded transactions after a simulated network delay.
/// Toggle via provider override in dev builds (ADR-MOCK-SWAP).
/// Mock user IDs to avoid duplicating string literals.
const _currentUser = 'user-current';
const _seller = 'user-seller';

class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository() {
    if (kReleaseMode) {
      throw StateError(
        'MockTransactionRepository cannot be used in release builds',
      );
    }
  }

  static final _fixtures = <String, TransactionEntity>{
    'txn-001': TransactionEntity(
      id: 'txn-001',
      listingId: 'listing-001',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.released,
      itemAmountCents: 2500,
      platformFeeCents: 63,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 3, 2),
      releasedAt: DateTime(2026, 3, 10),
    ),
    'txn-002': TransactionEntity(
      id: 'txn-002',
      listingId: 'listing-010',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.released,
      itemAmountCents: 5000,
      platformFeeCents: 125,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 3, 15),
      releasedAt: DateTime(2026, 3, 20),
    ),
    'txn-003': TransactionEntity(
      id: 'txn-003',
      listingId: 'listing-020',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.released,
      itemAmountCents: 7500,
      platformFeeCents: 188,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 3, 20),
      releasedAt: DateTime(2026, 3, 25),
    ),
    'txn-cancelled': TransactionEntity(
      id: 'txn-cancelled',
      listingId: 'listing-030',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.cancelled,
      itemAmountCents: 1500,
      platformFeeCents: 38,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 3, 5),
    ),
    'txn-pending': TransactionEntity(
      id: 'txn-pending',
      listingId: 'listing-040',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.paid,
      itemAmountCents: 3000,
      platformFeeCents: 75,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 3, 8),
    ),
  };

  @override
  Future<TransactionEntity?> getTransaction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _fixtures[id];
  }

  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _fixtures.values
        .where((t) => t.buyerId == userId || t.sellerId == userId)
        .toList();
  }

  @override
  Future<TransactionEntity> createTransaction({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  }) async {
    throw UnimplementedError('Mock: createTransaction not needed for reviews');
  }

  @override
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  }) async {
    throw UnimplementedError('Mock: updateStatus not needed for reviews');
  }

  @override
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  }) async {
    throw UnimplementedError('Mock: setMolliePaymentId not needed for reviews');
  }

  @override
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  }) async {
    throw UnimplementedError('Mock: setEscrowDeadline not needed for reviews');
  }
}
