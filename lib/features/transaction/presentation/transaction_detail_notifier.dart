import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';

/// Provider family keyed by transaction ID — fetches a single transaction.
final transactionDetailProvider =
    AutoDisposeFutureProvider.family<TransactionEntity, String>((
      ref,
      id,
    ) async {
      final repo = ref.watch(transactionRepositoryProvider);
      final txn = await repo.getTransaction(id);
      if (txn == null) throw Exception('Transaction not found');
      return txn;
    });
