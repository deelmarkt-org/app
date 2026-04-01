import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/ledger_entry.dart';
import 'package:deelmarkt/features/transaction/domain/exceptions.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/ledger_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

/// Records buyer→escrow ledger entry when payment completes.
///
/// Called by the webhook handler after Mollie confirms payment.
/// Reference: docs/ARCHITECTURE.md §Double-Entry Escrow Ledger
class RecordEscrowDepositUseCase {
  const RecordEscrowDepositUseCase({
    required this.transactionRepository,
    required this.ledgerRepository,
  });

  final TransactionRepository transactionRepository;
  final LedgerRepository ledgerRepository;

  Future<void> execute({
    required String transactionId,
    required String buyerId,
  }) async {
    final txn = await transactionRepository.getTransaction(transactionId);
    if (txn == null) throw TransactionNotFoundException(transactionId);

    if (txn.status != TransactionStatus.paid) {
      throw InvalidTransitionException(
        currentStatus: txn.status,
        attemptedStatus: TransactionStatus.paid,
      );
    }

    // B-20: Entry 1 — Buyer → escrow (full amount including shipping)
    await ledgerRepository.recordEntry(
      transactionId: transactionId,
      idempotencyKey: 'deposit:buyer:$transactionId',
      debitAccount: LedgerAccounts.buyer(buyerId),
      creditAccount: LedgerAccounts.escrow(transactionId),
      amountCents: txn.totalAmountCents,
    );

    // B-20: Entry 2 — Platform fee split (escrow → platform commission)
    // Immediately accounts for platform revenue at payment time.
    if (txn.platformFeeCents > 0) {
      await ledgerRepository.recordEntry(
        transactionId: transactionId,
        idempotencyKey: 'fee:platform:$transactionId',
        debitAccount: LedgerAccounts.escrow(transactionId),
        creditAccount: LedgerAccounts.platform,
        amountCents: txn.platformFeeCents,
      );
    }
  }
}
