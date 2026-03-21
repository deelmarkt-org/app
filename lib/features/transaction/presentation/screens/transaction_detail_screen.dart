import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import '../../domain/entities/transaction_entity.dart';
import '../widgets/action_section.dart';
import '../widgets/amount_section.dart';

/// Transaction detail screen — shows escrow timeline, amounts, and actions.
///
/// Reference: docs/design-system/patterns.md §Escrow Timeline
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('transaction.status'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EscrowTrustBanner(),
            const SizedBox(height: Spacing.s6),
            EscrowTimeline(
              currentStatus: transaction.status,
              escrowDeadline: transaction.escrowDeadline,
            ),
            const SizedBox(height: Spacing.s6),
            AmountSection(transaction: transaction),
            const SizedBox(height: Spacing.s6),
            ActionSection(transaction: transaction),
          ],
        ),
      ),
    );
  }
}
