/// Immutable double-entry ledger record for the escrow system.
///
/// Append-only — once created, never updated or deleted (PSD2 compliance).
/// Each financial event creates one or more entries that must balance.
///
/// Reference: docs/ARCHITECTURE.md §Double-Entry Escrow Ledger
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.transactionId,
    required this.idempotencyKey,
    required this.debitAccount,
    required this.creditAccount,
    required this.amountCents,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String transactionId;

  /// Unique key to prevent duplicate entries from webhook retries.
  final String idempotencyKey;

  /// Account debited (e.g. 'buyer:uuid', 'escrow:txn_uuid').
  final String debitAccount;

  /// Account credited (e.g. 'escrow:txn_uuid', 'seller:uuid').
  final String creditAccount;

  /// Amount in cents — always positive.
  final int amountCents;

  /// ISO 4217 currency code.
  final String currency;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LedgerEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Standard account types for the double-entry ledger.
abstract final class LedgerAccounts {
  /// Buyer's account: `buyer:{userId}`.
  static String buyer(String userId) => 'buyer:$userId';

  /// Seller's account: `seller:{userId}`.
  static String seller(String userId) => 'seller:$userId';

  /// Escrow holding account: `escrow:{transactionId}`.
  static String escrow(String transactionId) => 'escrow:$transactionId';

  /// Platform commission account.
  static const String platform = 'platform:commission';
}
