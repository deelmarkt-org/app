import 'package:deelmarkt/features/transaction/domain/entities/ledger_entry.dart';

/// Repository interface for the double-entry escrow ledger.
///
/// Append-only — entries are never updated or deleted.
/// Domain layer — implementation in data layer (Supabase PostgreSQL).
///
/// Reference: docs/ARCHITECTURE.md §Double-Entry Escrow Ledger
abstract class LedgerRepository {
  /// Record a ledger entry with idempotency protection.
  ///
  /// If an entry with the same [idempotencyKey] already exists,
  /// returns the existing entry (no duplicate).
  Future<LedgerEntry> recordEntry({
    required String transactionId,
    required String idempotencyKey,
    required String debitAccount,
    required String creditAccount,
    required int amountCents,
    String currency = 'EUR',
  });

  /// Get all ledger entries for a transaction.
  Future<List<LedgerEntry>> getEntriesForTransaction(String transactionId);

  /// Get the total amount held in escrow for a transaction.
  Future<int> getEscrowBalance(String transactionId);
}
