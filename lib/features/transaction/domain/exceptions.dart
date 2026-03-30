import 'package:deelmarkt/core/models/transaction_status.dart';

/// Thrown when a transaction cannot be found.
class TransactionNotFoundException implements Exception {
  const TransactionNotFoundException(this.transactionId);
  final String transactionId;

  @override
  String toString() => 'Transaction not found: $transactionId';
}

/// Thrown when a status transition violates the state machine.
class InvalidTransitionException implements Exception {
  const InvalidTransitionException({
    required this.currentStatus,
    required this.attemptedStatus,
  });

  final TransactionStatus currentStatus;
  final TransactionStatus attemptedStatus;

  @override
  String toString() =>
      'Cannot transition from $currentStatus to $attemptedStatus';
}
