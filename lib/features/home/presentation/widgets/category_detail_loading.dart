import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Skeleton loading view for the category detail screen.
class CategoryDetailLoading extends StatelessWidget {
  const CategoryDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 28, width: 200),
            const SizedBox(height: Spacing.s6),
            const SkeletonBox(height: 16, width: 120),
            const SizedBox(height: Spacing.s3),
            Wrap(
              spacing: Spacing.s2,
              runSpacing: Spacing.s2,
              children: List.generate(
                5,
                (_) => const SkeletonBox(height: 44, width: 100),
              ),
            ),
            const SizedBox(height: Spacing.s6),
            const SkeletonBox(height: 16, width: 160),
            const SizedBox(height: Spacing.s3),
            const Expanded(child: SkeletonBox(height: double.infinity)),
          ],
        ),
      ),
    );
  }
}
