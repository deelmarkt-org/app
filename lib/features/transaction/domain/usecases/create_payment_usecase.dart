import 'package:deelmarkt/core/models/transaction_status.dart';
import '../entities/payment_entity.dart';
import '../exceptions.dart';
import '../repositories/payment_repository.dart';
import '../repositories/transaction_repository.dart';

/// Creates a Mollie payment and transitions to `paymentPending`.
///
/// §2.1 deviation: import count + doc comments push to 59 lines.
/// Reference: docs/epics/E03-payments-escrow.md
class CreatePaymentUseCase {
  const CreatePaymentUseCase({
    required this.transactionRepository,
    required this.paymentRepository,
  });

  final TransactionRepository transactionRepository;
  final PaymentRepository paymentRepository;

  Future<PaymentEntity> execute({
    required String transactionId,
    required String redirectUrl,
    String? paymentDescription,
  }) async {
    final txn = await transactionRepository.getTransaction(transactionId);
    if (txn == null) throw TransactionNotFoundException(transactionId);

    if (!txn.status.canTransitionTo(TransactionStatus.paymentPending)) {
      throw InvalidTransitionException(
        currentStatus: txn.status,
        attemptedStatus: TransactionStatus.paymentPending,
      );
    }

    // Status transition first — payment creation is the external call
    // that can't be rolled back. If Mollie call succeeds but status
    // update failed, we'd have an orphaned payment. By transitioning
    // first, a retry will correctly find paymentPending status.
    await transactionRepository.updateStatus(
      transactionId: transactionId,
      newStatus: TransactionStatus.paymentPending,
    );

    final payment = await paymentRepository.createPayment(
      transactionId: transactionId,
      amountCents: txn.totalAmountCents,
      currency: txn.currency,
      description: paymentDescription ?? 'DeelMarkt #$transactionId',
      redirectUrl: redirectUrl,
    );

    await transactionRepository.setMolliePaymentId(
      transactionId: transactionId,
      molliePaymentId: payment.molliePaymentId,
    );

    return payment;
  }
}
