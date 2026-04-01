import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// Full profile skeleton loading state.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          children: [
            const SizedBox(height: Spacing.s8),
            // Avatar skeleton
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DeelmarktColors.white,
              ),
            ),
            const SizedBox(height: Spacing.s3),
            // Name skeleton
            Container(width: 120, height: 20, color: DeelmarktColors.white),
            const SizedBox(height: Spacing.s2),
            // Member since skeleton
            Container(width: 80, height: 14, color: DeelmarktColors.white),
            const SizedBox(height: Spacing.s6),
            // Stats row skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Column(
                  children: [
                    Container(
                      width: 40,
                      height: 24,
                      color: DeelmarktColors.white,
                    ),
                    const SizedBox(height: Spacing.s1),
                    Container(
                      width: 60,
                      height: 14,
                      color: DeelmarktColors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.s6),
            // Tab bar skeleton
            Container(
              width: double.infinity,
              height: 48,
              color: DeelmarktColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
