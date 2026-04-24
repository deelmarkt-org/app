import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/action_section.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/amount_section.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/escrow_step_detail_sheet.dart';

/// Transaction detail screen — shows escrow timeline, amounts, and actions.
///
/// Single-column stack on all viewports; `ResponsiveBody` caps at 900px on
/// expanded (≥840px) so the horizontal [EscrowTimeline] stepper renders in
/// its wide mode (threshold 360px) instead of its phone-narrow fallback.
/// A prior iteration of this PR (#206) tried a two-column `Row` with a
/// 320px right rail — that forced the horizontal stepper into its narrow
/// variant. Dropped per PR #207 review H-1.
///
/// Reference: docs/screens/04-payments/03-transaction-detail.md
/// Reference: docs/design-system/patterns.md §Escrow Timeline
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('transaction.status'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
          child: ResponsiveBody(
            // Wider than the default form cap — the horizontal EscrowTimeline
            // stepper reads better at 900px on tablet/desktop than at 600.
            maxWidth: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TrustBanner.escrow(),
                const SizedBox(height: Spacing.s6),
                EscrowTimeline(
                  currentStatus: transaction.status,
                  escrowDeadline: transaction.escrowDeadline,
                  onStepTapped:
                      (step) => EscrowStepDetailSheet.show(
                        context,
                        step: step,
                        transaction: transaction,
                      ),
                ),
                const SizedBox(height: Spacing.s6),
                AmountSection(transaction: transaction),
                const SizedBox(height: Spacing.s6),
                ActionSection(transaction: transaction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
