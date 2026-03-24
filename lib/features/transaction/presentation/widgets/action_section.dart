import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

import '../../domain/entities/transaction_entity.dart';

/// Action buttons based on transaction status.
class ActionSection extends StatelessWidget {
  const ActionSection({required this.transaction, super.key});

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
            onPressed:
                null, // Phase 2 (belengaz): wire to ConfirmDeliveryUseCase via Riverpod provider.
          ),
          const SizedBox(height: Spacing.s3),
          DeelButton(
            label: 'escrow.disputeOrder'.tr(),
            leadingIcon: PhosphorIcons.warningCircle(),
            variant: DeelButtonVariant.destructive,
            onPressed:
                null, // Phase 2 (belengaz): wire to dispute flow via Riverpod provider.
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
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
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
      ),
    );
  }
}
