import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/features/transaction/domain/entities/payment_entity.dart';
import 'package:deelmarkt/features/transaction/domain/exceptions.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/payment_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

/// Creates a Mollie payment and transitions to `paymentPending`. See
/// docs/epics/E03-payments-escrow.md.
class CreatePaymentUseCase {
  const CreatePaymentUseCase({
    required this.transactionRepository,
    required this.paymentRepository,
    required this.performanceTracer,
  });
  final TransactionRepository transactionRepository;
  final PaymentRepository paymentRepository;
  final PerformanceTracer performanceTracer;

  Future<PaymentEntity> execute({
    required String transactionId,
    required String redirectUrl,
    String? paymentDescription,
  }) async {
    // GH #221 payment_create trace; finally closes on any throw too.
    final handle = performanceTracer.start(TraceNames.paymentCreate);
    try {
      final txn = await transactionRepository.getTransaction(transactionId);
      if (txn == null) throw TransactionNotFoundException(transactionId);
      if (!txn.status.canTransitionTo(TransactionStatus.paymentPending)) {
        throw InvalidTransitionException(
          currentStatus: txn.status,
          attemptedStatus: TransactionStatus.paymentPending,
        );
      }
      // Status transition first so a retry finds paymentPending after a
      // crash between Mollie call and DB update (no orphan payments).
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
    } finally {
      await handle.stop();
    }
  }
}
