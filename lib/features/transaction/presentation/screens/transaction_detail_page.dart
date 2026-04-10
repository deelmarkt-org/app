import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/async_page.dart';

import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:deelmarkt/features/transaction/presentation/transaction_detail_notifier.dart';

/// Route-facing page for `/transactions/:id`.
///
/// Fetches the transaction by ID via [transactionDetailProvider],
/// handles loading/error states, and renders [TransactionDetailScreen].
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncPage(
      title: 'transaction.status'.tr(),
      state: ref.watch(transactionDetailProvider(transactionId)),
      onRetry: () => ref.invalidate(transactionDetailProvider(transactionId)),
      builder: (txn) => TransactionDetailScreen(transaction: txn),
    );
  }
}
