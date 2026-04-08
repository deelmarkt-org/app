import 'package:flutter/material.dart';

import 'package:deelmarkt/widgets/trust/escrow_step_tokens.dart';

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
