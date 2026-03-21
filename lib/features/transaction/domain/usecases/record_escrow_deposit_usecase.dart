import 'package:deelmarkt/core/models/transaction_status.dart';
import '../entities/ledger_entry.dart';
import '../exceptions.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/transaction_repository.dart';

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

    // Buyer → escrow (full amount including shipping)
    await ledgerRepository.recordEntry(
      transactionId: transactionId,
      idempotencyKey: 'deposit:buyer:$transactionId',
      debitAccount: LedgerAccounts.buyer(buyerId),
      creditAccount: LedgerAccounts.escrow(transactionId),
      amountCents: txn.totalAmountCents,
    );
  }
}
