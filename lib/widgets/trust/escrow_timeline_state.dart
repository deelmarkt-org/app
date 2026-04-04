/// Visual-state model for the [EscrowTimeline] widget.
///
/// `computeEscrowTimelineState` is the pure-Dart single source of truth for
/// every [TransactionStatus] branch (E03 payment path requires 100% coverage
/// per CLAUDE.md §6.1). The surrounding [EscrowTimelineVisualState] extension
/// methods expose theme-aware colour helpers so the widget itself can stay
/// declarative.
///
/// Reference: docs/design-system/patterns.md §Escrow Timeline
library;

import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_circle.dart';

/// Ordered happy-path timeline steps. Off-path states still anchor to one
/// of these via [EscrowTimelineVisualState.activeStepIndex].
enum EscrowTimelineStep {
  paid(TransactionStatus.paid),
  shipped(TransactionStatus.shipped),
  delivered(TransactionStatus.delivered),
  confirmed(TransactionStatus.confirmed),
  released(TransactionStatus.released);

  const EscrowTimelineStep(this.status);
  final TransactionStatus status;
}

/// High-level timeline shape: happy path, dispute, or terminal failure.
enum EscrowTimelineShape {
  happyPath,
  disputed,
  terminalResolved,
  terminalRefunded,
  cancelled,
  awaitingPayment,
}

/// Immutable visual description of an [EscrowTimeline] for a given status.
class EscrowTimelineVisualState {
  const EscrowTimelineVisualState({
    required this.shape,
    required this.activeStepIndex,
    required this.completedStepCount,
    required this.showDeadline,
    required this.statusLabelKey,
  });

  /// High-level timeline shape (drives overall colouring).
  final EscrowTimelineShape shape;

  /// Index (0-4) of the currently active step, or `-1` when the timeline
  /// sits before the first step (e.g. `paymentPending`).
  final int activeStepIndex;

  /// Number of fully-completed steps.
  final int completedStepCount;

  /// Whether a deadline countdown should render next to the active step.
  final bool showDeadline;

  /// Localisation key for the status banner (e.g. `escrow.disputed`).
  final String statusLabelKey;

  /// Whether the timeline is in a terminal state (no further progression).
  bool get isTerminal => switch (shape) {
    EscrowTimelineShape.terminalResolved ||
    EscrowTimelineShape.terminalRefunded ||
    EscrowTimelineShape.cancelled => true,
    _ => false,
  };

  /// Whether the overall timeline should render with muted colours
  /// (cancelled / refunded / awaiting payment).
  bool get isMuted => switch (shape) {
    EscrowTimelineShape.cancelled ||
    EscrowTimelineShape.terminalRefunded ||
    EscrowTimelineShape.awaitingPayment => true,
    _ => false,
  };

  bool _isDisputedAnchor(int stepIndex) =>
      shape == EscrowTimelineShape.disputed && stepIndex == activeStepIndex;

  /// Tone for the circle/connector at [stepIndex].
  EscrowStepTone toneAt(int stepIndex) {
    if (_isDisputedAnchor(stepIndex)) return EscrowStepTone.warning;
    if (isMuted) return EscrowStepTone.muted;
    return EscrowStepTone.trust;
  }

  /// Accent colour used by connectors between steps.
  Color accentAt(int stepIndex) => switch (toneAt(stepIndex)) {
    EscrowStepTone.trust => DeelmarktColors.trustEscrow,
    EscrowStepTone.warning => DeelmarktColors.trustWarning,
    EscrowStepTone.muted => DeelmarktColors.neutral500,
  };

  /// Label colour for the step text at [stepIndex].
  Color labelColor(
    BuildContext context,
    int stepIndex, {
    required bool isActive,
    required bool isComplete,
  }) {
    if (isMuted) return DeelmarktColors.neutral500;
    if (_isDisputedAnchor(stepIndex)) return DeelmarktColors.trustWarning;
    if (isActive || isComplete) return DeelmarktColors.trustEscrow;
    return Theme.of(context).brightness == Brightness.dark
        ? DeelmarktColors.neutral500
        : DeelmarktColors.neutral300;
  }
}

/// Compute the [EscrowTimelineVisualState] for the given [status].
///
/// Single source of truth for every off-path state the widget used to
/// silently fall through on (fix A1).
EscrowTimelineVisualState computeEscrowTimelineState(TransactionStatus status) {
  return switch (status) {
    TransactionStatus.created ||
    TransactionStatus.paymentPending => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.awaitingPayment,
      activeStepIndex: -1,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: 'transaction.paymentPending',
    ),
    TransactionStatus.paid => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: 0,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: 'transaction.paid',
    ),
    TransactionStatus.shipped => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: 1,
      completedStepCount: 1,
      showDeadline: false,
      statusLabelKey: 'transaction.shipped',
    ),
    TransactionStatus.delivered => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: 2,
      completedStepCount: 2,
      showDeadline: true,
      statusLabelKey: 'transaction.delivered',
    ),
    TransactionStatus.confirmed => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: 3,
      completedStepCount: 3,
      showDeadline: false,
      statusLabelKey: 'transaction.confirmed',
    ),
    TransactionStatus.released => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: 4,
      completedStepCount: 4,
      showDeadline: false,
      statusLabelKey: 'transaction.released',
    ),
    // Dispute anchors on the `delivered` step — where the 48-hour
    // confirmation window opens to the buyer.
    TransactionStatus.disputed => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.disputed,
      activeStepIndex: 2,
      completedStepCount: 2,
      showDeadline: false,
      statusLabelKey: 'escrow.disputed',
    ),
    TransactionStatus.resolved => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.terminalResolved,
      activeStepIndex: 4,
      completedStepCount: 4,
      showDeadline: false,
      statusLabelKey: 'escrow.terminalResolved',
    ),
    TransactionStatus.refunded => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.terminalRefunded,
      activeStepIndex: -1,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: 'escrow.terminalRefunded',
    ),
    TransactionStatus.expired ||
    TransactionStatus.failed ||
    TransactionStatus.cancelled => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.cancelled,
      activeStepIndex: -1,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: 'escrow.cancelled',
    ),
  };
}
