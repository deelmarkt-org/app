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
  static const double trustBannerBorderWidth = 3;
  static const double iconSize = 24;

  /// Minimum tappable area — WCAG 2.2 AA (44x44px).
  static const double minTapTarget = 44;
}

/// Step circle for [EscrowTimeline] — complete, active, or pending.
class EscrowStepCircle extends StatelessWidget {
  const EscrowStepCircle({
    required this.isComplete,
    required this.isActive,
    this.semanticLabel,
    super.key,
  });

  final bool isComplete;
  final bool isActive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: EscrowStepTokens.minTapTarget,
        height: EscrowStepTokens.minTapTarget,
        child: Center(child: _buildCircle()),
      ),
    );
  }

  Widget _buildCircle() {
    if (isComplete) {
      return Container(
        width: EscrowStepTokens.circleSize,
        height: EscrowStepTokens.circleSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: DeelmarktColors.trustEscrow,
        ),
        child: Icon(
          PhosphorIcons.check(PhosphorIconsStyle.bold),
          size: EscrowStepTokens.checkIconSize,
          color: DeelmarktColors.white,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: EscrowStepTokens.circleSize,
        height: EscrowStepTokens.circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DeelmarktColors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: DeelmarktColors.primary,
            width: EscrowStepTokens.borderWidth,
          ),
        ),
        child: Center(
          child: Container(
            width: EscrowStepTokens.innerDotSize,
            height: EscrowStepTokens.innerDotSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DeelmarktColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: EscrowStepTokens.circleSize,
      height: EscrowStepTokens.circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: DeelmarktColors.neutral300,
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
