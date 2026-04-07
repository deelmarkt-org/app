import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Size and style constants for escrow step circles.
abstract final class EscrowStepTokens {
  static const double circleSize = 24;
  static const double innerDotSize = 8;
  static const double borderWidth = 2;
  static const double checkIconSize = 14;
  static const double connectorDashWidth = 4;
  static const double connectorDashGap = 3;
  static const double connectorHeight = 2;

  /// Minimum tappable area — WCAG 2.2 AA (44x44px).
  static const double minTapTarget = 44;

  /// Pulse animation duration for the active state (fix A8).
  static const Duration pulseDuration = Duration(milliseconds: 1200);

  /// Pulse animation scale range — 1.0 → 1.12 → 1.0.
  static const double pulseMaxScale = 1.12;

  /// Stepper row height at wide layouts (≥ 360 px).
  static const double rowHeightWide = 104;

  /// Stepper row height at narrow layouts (< 360 px) — extra space for the
  /// 2-line label wrap plus the deadline hint.
  static const double rowHeightNarrow = 120;

  /// Connector vertical offset so the line aligns with the middle of the
  /// circle, regardless of tap-target padding.
  static const double connectorTopOffset = (minTapTarget - connectorHeight) / 2;

  /// Step label font size at narrow layouts.
  static const double narrowLabelFontSize = 10;

  /// Deadline-hint font size + top padding.
  static const double deadlineHintFontSize = 10;
  static const double deadlineHintTopPadding = 2;
}

/// Visual tone for an [EscrowStepCircle].
///
/// Drives colour selection so the widget stays theme- and state-aware
/// without hard-coding brand tokens for every branch (fix A3).
enum EscrowStepTone { trust, warning, muted }

/// Step circle for `EscrowTimeline` — complete, active, or pending.
///
/// Active state pulses with [TweenAnimationBuilder] unless
/// `MediaQuery.disableAnimations` is true (§10).
class EscrowStepCircle extends StatefulWidget {
  const EscrowStepCircle({
    required this.isComplete,
    required this.isActive,
    this.tone = EscrowStepTone.trust,
    this.semanticLabel,
    super.key,
  });

  final bool isComplete;
  final bool isActive;
  final EscrowStepTone tone;
  final String? semanticLabel;

  @override
  State<EscrowStepCircle> createState() => _EscrowStepCircleState();
}

class _EscrowStepCircleState extends State<EscrowStepCircle>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant EscrowStepCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  void _syncController() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isActive && !reduceMotion) {
      _controller ??= AnimationController(
        vsync: this,
        duration: EscrowStepTokens.pulseDuration,
      );
      if (!_controller!.isAnimating) {
        _controller!.repeat(reverse: true);
      }
    } else {
      _controller?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        width: EscrowStepTokens.minTapTarget,
        height: EscrowStepTokens.minTapTarget,
        child: Center(child: _buildCircle(context, reduceMotion)),
      ),
    );
  }

  Widget _buildCircle(BuildContext context, bool reduceMotion) {
    if (widget.isComplete) {
      return _CompleteCircle(tone: widget.tone);
    }
    if (widget.isActive) {
      if (reduceMotion || _controller == null) {
        return _ActiveCircle(scale: 1, tone: widget.tone);
      }
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller!.value);
          final scale = 1 + ((EscrowStepTokens.pulseMaxScale - 1) * t);
          return _ActiveCircle(scale: scale, tone: widget.tone);
        },
      );
    }
    return _PendingCircle(tone: widget.tone);
  }
}

/// Circle-fill colour for the currently **active** step.
///
/// Per `docs/design-system/patterns.md:49` and
/// `docs/screens/04-payments/03-transaction-detail.md:46` the active step
/// uses `primary` orange (pulsing) — distinct from `trust-escrow` blue,
/// which is reserved for completed segments and the escrow protection
/// banner.
Color escrowActiveColor(EscrowStepTone tone) => switch (tone) {
  EscrowStepTone.trust => DeelmarktColors.primary,
  EscrowStepTone.warning => DeelmarktColors.trustWarning,
  // muted never renders an active step in the current mapper — kept for
  // exhaustive-switch coverage.
  EscrowStepTone.muted => DeelmarktColors.neutral700,
};

/// Circle-fill colour for **completed** steps and for the connector
/// between two completed steps. Matches `trust-escrow` blue per
/// `patterns.md:48` ("Complete: filled + checkmark `trust-escrow` blue").
Color escrowCompleteColor(EscrowStepTone tone) => switch (tone) {
  EscrowStepTone.trust => DeelmarktColors.trustEscrow,
  EscrowStepTone.warning => DeelmarktColors.trustWarning,
  EscrowStepTone.muted => DeelmarktColors.neutral700,
};

/// Border / connector colour for **pending** steps.
///
/// `muted` (cancelled / refunded / awaiting-payment) returns a distinctly
/// dimmer shade than happy-path pending so the two visual states remain
/// distinguishable under both light and dark themes (PR #67 review #3).
/// Shared between [EscrowStepCircle] pending borders and
/// [EscrowTimeline] pending connectors so there is a single source of
/// truth (PR #67 review #4).
Color escrowPendingColor(BuildContext context, {bool muted = false}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (muted) {
    return isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral500;
  }
  return isDark ? DeelmarktColors.neutral500 : DeelmarktColors.neutral300;
}

class _CompleteCircle extends StatelessWidget {
  const _CompleteCircle({required this.tone});
  final EscrowStepTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EscrowStepTokens.circleSize,
      height: EscrowStepTokens.circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: escrowCompleteColor(tone),
      ),
      child: Icon(
        PhosphorIcons.check(PhosphorIconsStyle.bold),
        size: EscrowStepTokens.checkIconSize,
        color: DeelmarktColors.white,
      ),
    );
  }
}

class _ActiveCircle extends StatelessWidget {
  const _ActiveCircle({required this.scale, required this.tone});
  final double scale;
  final EscrowStepTone tone;

  @override
  Widget build(BuildContext context) {
    // Active uses `primary` orange per patterns.md §Escrow Timeline.
    final accent = escrowActiveColor(tone);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: EscrowStepTokens.circleSize,
        height: EscrowStepTokens.circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.15),
          border: Border.all(
            color: accent,
            width: EscrowStepTokens.borderWidth,
          ),
        ),
        child: Center(
          child: Container(
            width: EscrowStepTokens.innerDotSize,
            height: EscrowStepTokens.innerDotSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
        ),
      ),
    );
  }
}

class _PendingCircle extends StatelessWidget {
  const _PendingCircle({required this.tone});
  final EscrowStepTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EscrowStepTokens.circleSize,
      height: EscrowStepTokens.circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: escrowPendingColor(
            context,
            muted: tone == EscrowStepTone.muted,
          ),
          width: EscrowStepTokens.borderWidth,
        ),
      ),
    );
  }
}

/// Connector line between steps — solid (complete) or dashed (pending).
class EscrowConnectorPainter extends CustomPainter {
  const EscrowConnectorPainter({
    required this.isComplete,
    required this.completeColor,
    required this.pendingColor,
  });

  final bool isComplete;
  final Color completeColor;
  final Color pendingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isComplete ? completeColor : pendingColor
          ..strokeWidth = EscrowStepTokens.connectorHeight
          ..style = isComplete ? PaintingStyle.fill : PaintingStyle.stroke;

    if (isComplete) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x + EscrowStepTokens.connectorDashWidth, size.height / 2),
          paint,
        );
        x +=
            EscrowStepTokens.connectorDashWidth +
            EscrowStepTokens.connectorDashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant EscrowConnectorPainter oldDelegate) =>
      isComplete != oldDelegate.isComplete;
}
