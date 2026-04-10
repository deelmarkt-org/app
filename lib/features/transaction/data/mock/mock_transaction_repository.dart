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
  MockTransactionRepository() : _data = Map.of(_seed) {
    if (kReleaseMode) {
      throw StateError(
        'MockTransactionRepository cannot be used in release builds',
      );
    }
  }

  /// Instance-level copy so mutations don't leak across test runs.
  final Map<String, TransactionEntity> _data;

  static final _seed = <String, TransactionEntity>{
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
    'txn-shipped': TransactionEntity(
      id: 'txn-shipped',
      listingId: 'listing-050',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.shipped,
      itemAmountCents: 4500,
      platformFeeCents: 113,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 4),
      paidAt: DateTime(2026, 4),
      shippedAt: DateTime(2026, 4, 2),
    ),
    'txn-delivered': TransactionEntity(
      id: 'txn-delivered',
      listingId: 'listing-060',
      buyerId: _currentUser,
      sellerId: _seller,
      status: TransactionStatus.delivered,
      itemAmountCents: 6000,
      platformFeeCents: 150,
      shippingCostCents: 495,
      currency: 'EUR',
      createdAt: DateTime(2026, 4, 3),
      paidAt: DateTime(2026, 4, 3),
      shippedAt: DateTime(2026, 4, 4),
      deliveredAt: DateTime(2026, 4, 6),
      escrowDeadline: DateTime(2026, 4, 8),
    ),
  };

  @override
  Future<TransactionEntity?> getTransaction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _data[id];
  }

  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _data.values
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final txn = _data[transactionId];
    if (txn == null) throw Exception('Transaction not found');
    final updated = txn.copyWith(status: newStatus);
    _data[transactionId] = updated;
    return updated;
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
