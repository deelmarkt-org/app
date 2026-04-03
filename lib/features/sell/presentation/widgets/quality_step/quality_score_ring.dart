import 'dart:math';

import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';

/// Animated circular progress indicator showing the quality score.
///
/// Color changes based on score:
/// - < 40: error (red) — blocks publishing
/// - 40–70: warning (amber)
/// - > 70: success (green)
///
/// Respects [MediaQuery.disableAnimations] for reduced motion.
class QualityScoreRing extends StatefulWidget {
  const QualityScoreRing({required this.score, this.size = 160, super.key});

  final int score;
  final double size;

  @override
  State<QualityScoreRing> createState() => _QualityScoreRingState();
}

class _QualityScoreRingState extends State<QualityScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DeelmarktAnimation.emphasis,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DeelmarktAnimation.curveStandard,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(QualityScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: DeelmarktAnimation.curveStandard,
        ),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.score < 40) return DeelmarktColors.error;
    if (widget.score <= 70) return DeelmarktColors.warning;
    return DeelmarktColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.score}/100',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              progress: _animation.value,
              color: _color,
              bgColor: DeelmarktColors.neutral200,
            ),
            child: child,
          );
        },
        child: SizedBox.square(
          dimension: widget.size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.score}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                Text(
                  '/100',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DeelmarktColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  final double progress;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final fgPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
