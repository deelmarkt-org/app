import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
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
/// - Compact (<840px): everything stacked in a single column (timeline
///   renders at the top as the visual anchor, matching the mobile stitch
///   designs in `docs/screens/04-payments/designs/`).
/// - Expanded (≥840px): two-column `Row` — main content (TrustBanner +
///   AmountSection + ActionSection) on the left, EscrowTimeline pinned as
///   a 320px right rail so it stays in view while the user scrolls the
///   main content.
///
/// Reference: docs/screens/04-payments/03-transaction-detail.md §Expanded
/// Reference: docs/design-system/patterns.md §Escrow Timeline
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({required this.transaction, super.key});

  static const double _timelineRailWidth = 320;

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('transaction.status'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
        child: ResponsiveBody(
          maxWidth: 900,
          child:
              Breakpoints.isExpanded(context)
                  ? _buildExpanded(context)
                  : _buildCompact(context),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TrustBanner.escrow(),
        const SizedBox(height: Spacing.s6),
        _buildTimeline(context),
        const SizedBox(height: Spacing.s6),
        AmountSection(transaction: transaction),
        const SizedBox(height: Spacing.s6),
        ActionSection(transaction: transaction),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TrustBanner.escrow(),
              const SizedBox(height: Spacing.s6),
              AmountSection(transaction: transaction),
              const SizedBox(height: Spacing.s6),
              ActionSection(transaction: transaction),
            ],
          ),
        ),
        const SizedBox(width: Spacing.s6),
        SizedBox(width: _timelineRailWidth, child: _buildTimeline(context)),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return EscrowTimeline(
      currentStatus: transaction.status,
      escrowDeadline: transaction.escrowDeadline,
      onStepTapped:
          (step) => EscrowStepDetailSheet.show(
            context,
            step: step,
            transaction: transaction,
          ),
    );
  }
}
