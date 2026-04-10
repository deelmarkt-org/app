import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/transaction_detail_notifier.dart';

/// Action buttons based on transaction status.
///
/// Uses [ConsumerStatefulWidget] for the `_isConfirming` loading guard
/// on the confirm-delivery button (escrow-releasing financial action).
/// Accepted §1.3 deviation: setState for ephemeral button loading state only.
class ActionSection extends ConsumerStatefulWidget {
  const ActionSection({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  ConsumerState<ActionSection> createState() => _ActionSectionState();
}

class _ActionSectionState extends ConsumerState<ActionSection> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
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
            isLoading: _isConfirming,
            onPressed: _isConfirming ? null : _confirmDelivery,
          ),
          const SizedBox(height: Spacing.s3),
          DeelButton(
            label: 'escrow.disputeOrder'.tr(),
            leadingIcon: PhosphorIcons.warningCircle(),
            variant: DeelButtonVariant.destructive,
            // Dispute flow blocked by R-37 (account suspension/appeal tables).
            onPressed:
                () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('action.comingSoon'.tr())),
                ),
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

  Future<void> _confirmDelivery() async {
    setState(() => _isConfirming = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updateStatus(
        transactionId: widget.transaction.id,
        newStatus: TransactionStatus.confirmed,
      );
      ref.invalidate(transactionDetailProvider(widget.transaction.id));
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error.generic'.tr())));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
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
