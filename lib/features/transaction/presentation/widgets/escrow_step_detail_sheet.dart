import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline_state.dart';

/// Bottom sheet showing timestamp details for a tapped escrow timeline step.
///
/// Opened via [EscrowStepDetailSheet.show] when the user taps a step in
/// [EscrowTimeline]. Displays the step name, its completion timestamp (or a
/// "not yet reached" indicator), and contextual data for the delivered step
/// (escrow deadline, disputed timestamp).
///
/// Reference: docs/design-system/patterns.md §Escrow Timeline
class EscrowStepDetailSheet extends StatelessWidget {
  const EscrowStepDetailSheet({
    required this.stepIndex,
    required this.transaction,
    super.key,
  });

  final int stepIndex;
  final TransactionEntity transaction;

  /// Show this sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int stepIndex,
    required TransactionEntity transaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DeelmarktRadius.xl),
        ),
      ),
      builder:
          (_) => EscrowStepDetailSheet(
            stepIndex: stepIndex,
            transaction: transaction,
          ),
    );
  }

  DateTime? get _stepTimestamp => switch (stepIndex) {
    0 => transaction.paidAt,
    1 => transaction.shippedAt,
    2 => transaction.deliveredAt,
    3 => transaction.confirmedAt,
    4 => transaction.releasedAt,
    _ => null,
  };

  bool get _isDeliveredStep => stepIndex == 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final stepName = 'escrow.${EscrowTimelineStep.values[stepIndex].name}'.tr();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.s4,
        Spacing.s4,
        Spacing.s4,
        viewInsets.bottom + Spacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle — 40×4, outlineVariant, pill radius.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(DeelmarktRadius.full),
              ),
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Semantics(
            header: true,
            child: Text(stepName, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: Spacing.s4),
          _buildTimestampRow(context),
          ..._buildDeliveredExtras(),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = _stepTimestamp;
    if (timestamp != null) {
      return _DetailRow(
        label: 'escrow.stepDetail.completedAt'.tr(),
        value: Formatters.shortDateTime(timestamp),
      );
    }
    return Text(
      'escrow.stepDetail.notReached'.tr(),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<Widget> _buildDeliveredExtras() {
    if (!_isDeliveredStep) return const [];
    return [
      if (transaction.escrowDeadline != null) ...[
        const SizedBox(height: Spacing.s3),
        _DetailRow(
          label: 'escrow.stepDetail.deadline'.tr(),
          value: Formatters.shortDateTime(transaction.escrowDeadline!),
          valueColor: DeelmarktColors.primary,
        ),
      ],
      if (transaction.disputedAt != null) ...[
        const SizedBox(height: Spacing.s3),
        _DetailRow(
          label: 'escrow.stepDetail.disputedAt'.tr(),
          value: Formatters.shortDateTime(transaction.disputedAt!),
          valueColor: DeelmarktColors.trustWarning,
        ),
      ],
    ];
  }
}

/// A label + value row used inside [EscrowStepDetailSheet].
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
