import 'package:deelmarkt/core/models/transaction_status.dart';
import '../entities/ledger_entry.dart';
import '../exceptions.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/transaction_repository.dart';

/// Confirms delivery and records escrow release ledger entries.
///
/// Reference: docs/epics/E03-payments-escrow.md
class ConfirmDeliveryUseCase {
  const ConfirmDeliveryUseCase({
    required this.transactionRepository,
    required this.ledgerRepository,
  });

  final TransactionRepository transactionRepository;
  final LedgerRepository ledgerRepository;

  Future<void> execute({
    required String transactionId,
    required String sellerId,
  }) async {
    final txn = await transactionRepository.getTransaction(transactionId);
    if (txn == null) throw TransactionNotFoundException(transactionId);

    if (!txn.status.canTransitionTo(TransactionStatus.confirmed)) {
      throw InvalidTransitionException(
        currentStatus: txn.status,
        attemptedStatus: TransactionStatus.confirmed,
      );
    }

    // Escrow → seller (item price + shipping reimbursement)
    await ledgerRepository.recordEntry(
      transactionId: transactionId,
      idempotencyKey: 'release:seller:$transactionId',
      debitAccount: LedgerAccounts.escrow(transactionId),
      creditAccount: LedgerAccounts.seller(sellerId),
      amountCents: txn.sellerPayoutCents,
    );

    // Escrow → platform (commission)
    await ledgerRepository.recordEntry(
      transactionId: transactionId,
      idempotencyKey: 'release:platform:$transactionId',
      debitAccount: LedgerAccounts.escrow(transactionId),
      creditAccount: LedgerAccounts.platform,
      amountCents: txn.platformFeeCents,
    );

    await transactionRepository.updateStatus(
      transactionId: transactionId,
      newStatus: TransactionStatus.confirmed,
    );
  }
}
