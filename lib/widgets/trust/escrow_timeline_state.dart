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
/// of these via [EscrowTimelineVisualState.activeStepIndex]. The enum name
/// is the localisation key suffix (`escrow.${step.name}`).
enum EscrowTimelineStep { paid, shipped, delivered, confirmed, released }

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

  /// Localisation key for the status banner, rooted at `transaction.*`
  /// (e.g. `transaction.disputed`, `transaction.paid`).
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

  /// Accent colour used by **complete** connector segments between steps.
  /// Reuses the shared [escrowCompleteColor] so the connector and circle
  /// share a single source of truth (PR #67 review #4).
  Color accentAt(int stepIndex) => escrowCompleteColor(toneAt(stepIndex));

  /// Pending connector colour — delegates to the shared [escrowPendingColor]
  /// helper so connectors and circle borders never drift (PR #67 review #4).
  Color pendingConnectorColor(BuildContext context) =>
      escrowPendingColor(context, muted: isMuted);

  /// Label colour for the step text at [stepIndex].
  ///
  /// Active and complete labels match the circle fill:
  /// - active  → `primary` orange (patterns.md §Escrow Timeline)
  /// - complete → `trustEscrow` blue
  /// Muted labels get a distinctly dimmer shade than happy-path pending
  /// so cancelled timelines remain distinguishable under dark theme
  /// (PR #67 review #3).
  Color labelColor(
    BuildContext context,
    int stepIndex, {
    required bool isActive,
    required bool isComplete,
  }) {
    if (isMuted) return escrowPendingColor(context, muted: true);
    if (_isDisputedAnchor(stepIndex)) return DeelmarktColors.trustWarning;
    if (isActive) return DeelmarktColors.primary;
    if (isComplete) return DeelmarktColors.trustEscrow;
    return escrowPendingColor(context);
  }
}

/// Happy-path factory — the five steps visible on screen. Reduces
/// repetition inside [computeEscrowTimelineState].
EscrowTimelineVisualState _happy(int index, {bool showDeadline = false}) =>
    EscrowTimelineVisualState(
      shape: EscrowTimelineShape.happyPath,
      activeStepIndex: index,
      completedStepCount: index,
      showDeadline: showDeadline,
      statusLabelKey: 'transaction.${EscrowTimelineStep.values[index].name}',
    );

/// Cancelled / expired / failed shape factory with a status-specific
/// l10n key (review #9 — keep every statusLabelKey in the transaction.*
/// namespace).
EscrowTimelineVisualState _cancelled(String statusLabelKey) =>
    EscrowTimelineVisualState(
      shape: EscrowTimelineShape.cancelled,
      activeStepIndex: -1,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: statusLabelKey,
    );

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
    TransactionStatus.paid => _happy(0),
    TransactionStatus.shipped => _happy(1),
    TransactionStatus.delivered => _happy(2, showDeadline: true),
    TransactionStatus.confirmed => _happy(3),
    TransactionStatus.released => _happy(4),
    // Dispute anchors on the `delivered` step — the 48-hour confirmation
    // window opens to the buyer there.
    TransactionStatus.disputed => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.disputed,
      activeStepIndex: 2,
      completedStepCount: 2,
      showDeadline: false,
      statusLabelKey: 'transaction.disputed',
    ),
    TransactionStatus.resolved => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.terminalResolved,
      activeStepIndex: 4,
      completedStepCount: 4,
      showDeadline: false,
      statusLabelKey: 'transaction.resolved',
    ),
    TransactionStatus.refunded => const EscrowTimelineVisualState(
      shape: EscrowTimelineShape.terminalRefunded,
      activeStepIndex: -1,
      completedStepCount: 0,
      showDeadline: false,
      statusLabelKey: 'transaction.refunded',
    ),
    TransactionStatus.expired => _cancelled('transaction.expired'),
    TransactionStatus.failed => _cancelled('transaction.failed'),
    TransactionStatus.cancelled => _cancelled('transaction.cancelled'),
  };
}
