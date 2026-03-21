/// Represents a Mollie payment associated with a transaction.
///
/// Maps to Mollie's Payment API response.
/// Domain layer — no Mollie SDK or Supabase imports.
///
/// Reference: docs/epics/E03-payments-escrow.md
class PaymentEntity {
  const PaymentEntity({
    required this.id,
    required this.transactionId,
    required this.molliePaymentId,
    required this.status,
    required this.amountCents,
    required this.currency,
    required this.method,
    required this.createdAt,
    this.checkoutUrl,
    this.paidAt,
    this.expiresAt,
  });

  final String id;
  final String transactionId;

  /// Mollie payment ID (e.g. 'tr_H2GqAG6pT2zNYVzmQUeNJ').
  final String molliePaymentId;

  /// Mollie payment status.
  final PaymentStatus status;

  /// Amount in cents.
  final int amountCents;

  /// ISO 4217 currency code.
  final String currency;

  /// Payment method used (e.g. 'ideal', 'creditcard').
  final String method;

  /// Mollie checkout URL — buyer redirects here to complete payment.
  final String? checkoutUrl;

  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PaymentEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Mollie payment statuses.
///
/// Reference: https://docs.mollie.com/reference/payment-status-changes
enum PaymentStatus {
  /// Payment created, not yet started.
  open,

  /// Buyer is completing payment (e.g. in iDEAL bank app).
  pending,

  /// Payment authorized (for credit card / Klarna).
  authorized,

  /// Payment completed successfully.
  paid,

  /// Payment expired (buyer didn't complete in time).
  expired,

  /// Payment failed (bank declined, insufficient funds).
  failed,

  /// Payment was cancelled by buyer.
  canceled;

  /// Whether this is a successful terminal state.
  bool get isSuccessful => this == paid;

  /// Whether this is a failed terminal state.
  bool get isFailed => switch (this) {
    expired || failed || canceled => true,
    _ => false,
  };

  /// Whether the payment is still in progress.
  bool get isPending => switch (this) {
    open || pending || authorized => true,
    _ => false,
  };
}
