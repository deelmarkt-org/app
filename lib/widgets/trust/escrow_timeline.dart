import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';

/// Horizontal escrow timeline stepper.
///
/// Shows: Betaald → Verzonden → Bezorgd → Bevestigd → Uitbetaald
///
/// Reference: docs/design-system/patterns.md §Escrow Timeline
class EscrowTimeline extends StatelessWidget {
  const EscrowTimeline({
    required this.currentStatus,
    this.escrowDeadline,
    this.onStepTapped,
    super.key,
  });

  final TransactionStatus currentStatus;
  final DateTime? escrowDeadline;
  final void Function(int stepIndex)? onStepTapped;

  static const _steps = [
    TransactionStatus.paid,
    TransactionStatus.shipped,
    TransactionStatus.delivered,
    TransactionStatus.confirmed,
    TransactionStatus.released,
  ];

  int get _activeIndex {
    final idx = _steps.indexOf(currentStatus);
    return idx >= 0 ? idx : -1;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${'transaction.status'.tr()}: ${_statusLabel(currentStatus)}',
      child: SizedBox(
        height: 72,
        child: Row(
          children: List.generate(_steps.length * 2 - 1, (index) {
            if (index.isOdd) return _buildConnector(stepIndex: index ~/ 2);
            return _buildStep(context, stepIndex: index ~/ 2);
          }),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, {required int stepIndex}) {
    final step = _steps[stepIndex];
    final isComplete = _activeIndex > stepIndex;
    final isActive = _activeIndex == stepIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onStepTapped != null ? () => onStepTapped!(stepIndex) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EscrowStepCircle(
              isComplete: isComplete,
              isActive: isActive,
              semanticLabel: _stepLabel(step),
            ),
            const SizedBox(height: Spacing.s2),
            Text(
              _stepLabel(step),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    isComplete || isActive
                        ? DeelmarktColors.trustEscrow
                        : DeelmarktColors.neutral300,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive &&
                step == TransactionStatus.delivered &&
                escrowDeadline != null)
              Text(
                'escrow.countdownHint'.tr(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DeelmarktColors.primary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector({required int stepIndex}) {
    return SizedBox(
      width: Spacing.s4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.s6),
        child: CustomPaint(
          painter: EscrowConnectorPainter(
            isComplete: _activeIndex > stepIndex,
            completeColor: DeelmarktColors.trustEscrow,
            pendingColor: DeelmarktColors.neutral300,
          ),
          size: const Size(Spacing.s4, EscrowStepTokens.connectorHeight),
        ),
      ),
    );
  }

  String _stepLabel(TransactionStatus step) => switch (step) {
    TransactionStatus.paid => 'escrow.paid'.tr(),
    TransactionStatus.shipped => 'escrow.shipped'.tr(),
    TransactionStatus.delivered => 'escrow.delivered'.tr(),
    TransactionStatus.confirmed => 'escrow.confirmed'.tr(),
    TransactionStatus.released => 'escrow.released'.tr(),
    _ => '',
  };

  String _statusLabel(TransactionStatus status) =>
      'transaction.${status.name}'.tr();
}
