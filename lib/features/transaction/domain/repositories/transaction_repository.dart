import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';

/// Repository interface for transaction operations.
///
/// Domain layer — implementation in data layer (Supabase).
/// Throws `InvalidTransitionException` (from `exceptions.dart`) on invalid transitions.
abstract class TransactionRepository {
  /// Create a new transaction for a listing purchase.
  Future<TransactionEntity> createTransaction({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  });

  /// Get a transaction by ID.
  Future<TransactionEntity?> getTransaction(String id);

  /// Get all transactions for a user (as buyer or seller).
  Future<List<TransactionEntity>> getTransactionsForUser(String userId);

  /// Update transaction status with validation.
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  });

  /// Set the Mollie payment ID after payment creation.
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  });

  /// Set the escrow deadline (48h after delivery).
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  });
}
