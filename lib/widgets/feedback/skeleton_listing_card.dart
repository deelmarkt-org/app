import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Composite skeleton placeholder for a listing card.
///
/// Layout mirrors [ListingCard] (E01) — update if ListingCard changes.
///
/// Wraps all shapes in a single [SkeletonLoader] (one [AnimationController]).
///
/// ```
/// ┌─────────────────────────────┐
/// │  ░░░░░░░░░░░░░░░░░░░░░░░░  │  ← Image (180px)
/// ├─────────────────────────────┤
/// │  ░░░░░░░░                   │  ← Price (80×20)
/// │  ░░░░░░░░░░░░░░░            │  ← Title (200×16)
/// │  ○ ░░░░░░░░░░               │  ← Seller avatar + name
/// └─────────────────────────────┘
/// ```
///
/// Reference: docs/design-system/components.md §Loading — Shimmer Skeletons
class SkeletonListingCard extends StatelessWidget {
  const SkeletonListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder — Expanded so the skeleton fills whatever
            // height the parent grid cell allocates (e.g. childAspectRatio).
            //
            // ⚠️ CONSTRAINT: Expanded requires a bounded-height parent. This
            // widget is designed for use inside GridView (which provides bounds).
            // Using it in an unbounded context (e.g. ListView without a fixed
            // height) will throw a RenderFlex error. The SkeletonBox height:180
            // is overridden by Expanded and has no visual effect — it is kept
            // only as documentation of the intended image height when there is
            // no parent to constrain it.
            Expanded(
              child: SkeletonBox(height: 180, borderRadius: DeelmarktRadius.xl),
            ),
            Padding(
              padding: EdgeInsets.all(Spacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price placeholder.
                  SkeletonLine(width: 80, height: 20),
                  SizedBox(height: Spacing.s2),
                  // Title placeholder.
                  SkeletonLine(width: 200),
                  SizedBox(height: Spacing.s3),
                  // Seller avatar + name placeholder.
                  Row(
                    children: [
                      SkeletonCircle(size: 24),
                      SizedBox(width: Spacing.s2),
                      SkeletonLine(width: 100, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
