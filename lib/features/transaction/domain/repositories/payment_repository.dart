import '../entities/payment_entity.dart';

/// Repository interface for Mollie payment operations.
///
/// Domain layer — implementation in data layer (Mollie API via Supabase Edge Function).
abstract class PaymentRepository {
  /// Create a Mollie payment for a transaction.
  ///
  /// Returns a [PaymentEntity] with a [checkoutUrl] for the buyer to complete.
  Future<PaymentEntity> createPayment({
    required String transactionId,
    required int amountCents,
    required String currency,
    required String description,
    required String redirectUrl,
    String method = 'ideal',
  });

  /// Get the current payment status from Mollie.
  Future<PaymentEntity?> getPayment(String molliePaymentId);

  /// Get all payments for a transaction (handles retries).
  Future<List<PaymentEntity>> getPaymentsForTransaction(String transactionId);
}
