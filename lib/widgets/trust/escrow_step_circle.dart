import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/widgets/trust/escrow_step_tokens.dart';

export 'escrow_connector_painter.dart';
export 'escrow_step_tokens.dart';

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
