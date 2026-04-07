import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// Skeleton placeholder shown while the public profile is loading.
class PublicProfileSkeleton extends StatelessWidget {
  const PublicProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerLow;
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(height: Spacing.s3),
            Container(width: 120, height: 16, color: color),
            const SizedBox(height: Spacing.s2),
            Container(width: 80, height: 12, color: color),
          ],
        ),
      ),
    );
  }
}
