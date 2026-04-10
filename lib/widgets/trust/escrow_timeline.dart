import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline_state.dart';

/// Horizontal escrow timeline stepper.
///
/// Shows: Betaald → Verzonden → Bezorgd → Bevestigd → Uitbetaald. Off-path
/// states (disputed / refunded / cancelled / expired / failed /
/// paymentPending) render a muted variant with an explicit status label.
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
  final void Function(EscrowTimelineStep step)? onStepTapped;

  /// Breakpoint under which labels wrap to 2 lines (fix A5).
  static const double _narrowBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    final state = computeEscrowTimelineState(currentStatus);
    return Semantics(
      label: '${'transaction.status'.tr()}: ${state.statusLabelKey.tr()}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < _narrowBreakpoint;
          return SizedBox(
            height:
                isNarrow
                    ? EscrowStepTokens.rowHeightNarrow
                    : EscrowStepTokens.rowHeightWide,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                EscrowTimelineStep.values.length * 2 - 1,
                (i) =>
                    i.isOdd
                        ? _buildConnector(context, i ~/ 2, state)
                        : _buildStep(context, i ~/ 2, state, isNarrow),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    int stepIndex,
    EscrowTimelineVisualState state,
    bool isNarrow,
  ) {
    final step = EscrowTimelineStep.values[stepIndex];
    final isAtIndex = state.activeStepIndex == stepIndex;
    final rawComplete = state.completedStepCount > stepIndex;
    // `disputed` is NOT in `isTerminal` so a single `!isTerminal` check is
    // sufficient — no extra disputed disjunct needed (M1).
    final isActive = isAtIndex && !state.isTerminal;
    final showAsComplete =
        rawComplete ||
        (isAtIndex && state.shape == EscrowTimelineShape.terminalResolved);
    final labelText = 'escrow.${step.name}'.tr();
    final onTap = onStepTapped;

    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: EscrowStepTokens.minTapTarget,
        ),
        child: Semantics(
          button: onTap != null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap != null ? () => onTap(step) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EscrowStepCircle(
                    isComplete: showAsComplete,
                    isActive: isActive,
                    tone: state.toneAt(stepIndex),
                    semanticLabel: labelText,
                  ),
                  const SizedBox(height: Spacing.s2),
                  Text(
                    labelText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      // Pass `showAsComplete` so the label colour tracks the
                      // circle's visual state in terminal `resolved` (M2).
                      color: state.labelColor(
                        context,
                        stepIndex,
                        isActive: isActive,
                        isComplete: showAsComplete,
                      ),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize:
                          isNarrow
                              ? EscrowStepTokens.narrowLabelFontSize
                              : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isNarrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive && state.showDeadline && escrowDeadline != null)
                    _DeadlineHint(deadline: escrowDeadline!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(
    BuildContext context,
    int stepIndex,
    EscrowTimelineVisualState state,
  ) {
    return SizedBox(
      width: Spacing.s4,
      child: Padding(
        padding: const EdgeInsets.only(
          top: EscrowStepTokens.connectorTopOffset,
        ),
        child: CustomPaint(
          painter: EscrowConnectorPainter(
            isComplete: state.completedStepCount > stepIndex,
            completeColor: state.accentAt(stepIndex),
            // Shared helper — single source of truth between circle
            // borders and connectors (PR #67 review #4).
            pendingColor: state.pendingConnectorColor(context),
          ),
          size: const Size(Spacing.s4, EscrowStepTokens.connectorHeight),
        ),
      ),
    );
  }
}

class _DeadlineHint extends StatelessWidget {
  const _DeadlineHint({required this.deadline});
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: EscrowStepTokens.deadlineHintTopPadding,
      ),
      child: Text(
        'escrow.deadlineHint'.tr(
          namedArgs: {'date': Formatters.shortDateTime(deadline)},
        ),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DeelmarktColors.primary,
          fontSize: EscrowStepTokens.deadlineHintFontSize,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
