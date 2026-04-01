import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';

/// Animated progress bar for KYC verification steps.
class KycProgressBar extends StatelessWidget {
  const KycProgressBar({required this.progress, super.key});

  /// Progress value from 0.0 to 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = DeelmarktAnimation.resolve(
      const Duration(milliseconds: 300),
      reduceMotion: reduceMotion,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: DeelmarktColors.neutral200),
            AnimatedFractionallySizedBox(
              duration: duration,
              curve: DeelmarktAnimation.curveStandard,
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: DeelmarktColors.trustVerified,
                  borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
