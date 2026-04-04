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

Color _accentForTone(EscrowStepTone tone) => switch (tone) {
  EscrowStepTone.trust => DeelmarktColors.trustEscrow,
  EscrowStepTone.warning => DeelmarktColors.trustWarning,
  // muted accent is effectively unreachable in the current mapper
  // (muted states have no complete/active steps) — kept for
  // exhaustive-switch coverage and future-proofing.
  EscrowStepTone.muted => DeelmarktColors.neutral700,
};

Color _pendingBorderForTone(BuildContext context, EscrowStepTone tone) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // Muted (cancelled / refunded / awaiting-payment) gets a distinctly
  // dimmer border than happy-path pending so the two visual states remain
  // distinguishable under both themes (fixes PR #67 review finding #3).
  if (tone == EscrowStepTone.muted) {
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
        color: _accentForTone(tone),
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
    final accent = _accentForTone(tone);
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
          color: _pendingBorderForTone(context, tone),
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
