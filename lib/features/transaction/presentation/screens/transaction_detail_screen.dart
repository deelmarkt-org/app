import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import '../../domain/entities/transaction_entity.dart';

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
            _AmountSection(transaction: transaction),
            const SizedBox(height: Spacing.s6),
            _ActionSection(transaction: transaction),
          ],
        ),
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  const _AmountSection({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${'payment.total'.tr()} ${Formatters.euroFromCents(transaction.totalAmountCents)}',
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? DeelmarktColors.white,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(color: DeelmarktColors.neutral200),
        ),
        child: Column(
          children: [
            _row(
              context,
              'payment.itemPrice'.tr(),
              Formatters.euroFromCents(transaction.itemAmountCents),
            ),
            const SizedBox(height: Spacing.s2),
            _row(
              context,
              'payment.platformFee'.tr(),
              Formatters.euroFromCents(transaction.platformFeeCents),
            ),
            const SizedBox(height: Spacing.s2),
            _row(
              context,
              'payment.shippingCost'.tr(),
              Formatters.euroFromCents(transaction.shippingCostCents),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.s2),
              child: Divider(),
            ),
            _row(
              context,
              'payment.total'.tr(),
              Formatters.euroFromCents(transaction.totalAmountCents),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String amount, {
    bool isBold = false,
  }) {
    return Semantics(
      label: '$label $amount',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return switch (transaction.status) {
      TransactionStatus.paid => _infoRow(
        context,
        PhosphorIcons.hourglass(),
        'escrow.fundsHeld'.tr(),
        DeelmarktColors.trustEscrow,
      ),
      TransactionStatus.shipped => _infoRow(
        context,
        PhosphorIcons.package(),
        'escrow.shipped'.tr(),
        DeelmarktColors.trustEscrow,
      ),
      TransactionStatus.delivered => Column(
        children: [
          DeelButton(
            label: 'escrow.confirmDelivery'.tr(),
            leadingIcon: PhosphorIcons.checkCircle(),
            variant: DeelButtonVariant.success,
            onPressed: () {
              // TODO: Wire to ConfirmDeliveryUseCase via Riverpod provider
            },
          ),
          const SizedBox(height: Spacing.s3),
          DeelButton(
            label: 'escrow.disputeOrder'.tr(),
            leadingIcon: PhosphorIcons.warningCircle(),
            variant: DeelButtonVariant.destructive,
            onPressed: () {
              // TODO: Wire to dispute flow via Riverpod provider
            },
          ),
        ],
      ),
      TransactionStatus.confirmed || TransactionStatus.released => _infoRow(
        context,
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        'escrow.fundsReleased'.tr(),
        DeelmarktColors.trustVerified,
      ),
      TransactionStatus.disputed => _infoRow(
        context,
        PhosphorIcons.warningCircle(),
        'transaction.disputed'.tr(),
        DeelmarktColors.trustWarning,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: Spacing.s2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
