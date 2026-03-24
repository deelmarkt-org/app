import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

import 'skeleton_loader.dart';
import 'skeleton_shapes.dart';

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image placeholder.
            SkeletonBox(height: 180, borderRadius: DeelmarktRadius.xl),
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
