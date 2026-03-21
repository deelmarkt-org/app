import 'package:deelmarkt/core/models/transaction_status.dart';

/// Represents a marketplace transaction between buyer and seller.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// All monetary values in cents to avoid floating-point errors.
///
/// §2.1 deviation: 16-field entity requires verbose copyWith (118 lines).
///
/// Reference: docs/epics/E03-payments-escrow.md
class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.itemAmountCents,
    required this.platformFeeCents,
    required this.shippingCostCents,
    required this.currency,
    required this.createdAt,
    this.molliePaymentId,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.confirmedAt,
    this.releasedAt,
    this.disputedAt,
    this.escrowDeadline,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final TransactionStatus status;

  /// Item price in cents (e.g. 4500 = €45.00).
  final int itemAmountCents;

  /// Platform commission in cents (2.5% of item price).
  final int platformFeeCents;

  /// Shipping cost in cents.
  final int shippingCostCents;

  /// ISO 4217 currency code (always 'EUR' for MVP).
  final String currency;

  /// Mollie payment ID (set after payment initiation).
  final String? molliePaymentId;

  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? confirmedAt;
  final DateTime? releasedAt;
  final DateTime? disputedAt;

  /// Deadline for buyer to confirm or dispute (48h after delivery).
  final DateTime? escrowDeadline;

  /// Total amount the buyer pays (item + platform fee + shipping).
  int get totalAmountCents =>
      itemAmountCents + platformFeeCents + shippingCostCents;

  /// Amount the seller receives (item price + shipping reimbursement).
  /// Platform fee is paid by the buyer on top — not deducted from seller.
  int get sellerPayoutCents => itemAmountCents + shippingCostCents;

  /// Whether the 48-hour buyer confirmation window has expired.
  /// Pass [now] for testability; defaults to current time.
  bool isEscrowExpired({DateTime? now}) {
    if (escrowDeadline == null) return false;
    return (now ?? DateTime.now()).isAfter(escrowDeadline!);
  }

  /// Returns a copy with updated fields.
  TransactionEntity copyWith({
    TransactionStatus? status,
    String? molliePaymentId,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? confirmedAt,
    DateTime? releasedAt,
    DateTime? disputedAt,
    DateTime? escrowDeadline,
  }) {
    return TransactionEntity(
      id: id,
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      status: status ?? this.status,
      itemAmountCents: itemAmountCents,
      platformFeeCents: platformFeeCents,
      shippingCostCents: shippingCostCents,
      currency: currency,
      molliePaymentId: molliePaymentId ?? this.molliePaymentId,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      disputedAt: disputedAt ?? this.disputedAt,
      escrowDeadline: escrowDeadline ?? this.escrowDeadline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
