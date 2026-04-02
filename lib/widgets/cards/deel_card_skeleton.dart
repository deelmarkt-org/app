import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// Variant for skeleton shape.
enum DeelCardVariant { grid, list }

/// Shimmer skeleton placeholder matching [DeelCard] layout dimensions.
class DeelCardSkeleton extends StatelessWidget {
  const DeelCardSkeleton({this.variant = DeelCardVariant.grid, super.key});

  final DeelCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: variant == DeelCardVariant.grid ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeelCardTokens.borderRadius),
        color: DeelmarktColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio:
                DeelCardTokens.gridImageAspectWidth /
                DeelCardTokens.gridImageAspectHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DeelCardTokens.borderRadius),
                ),
                color: DeelmarktColors.neutral200,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(width: 60, height: 16),
                const SizedBox(height: Spacing.s2),
                _skeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: Spacing.s1),
                _skeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeelCardTokens.borderRadius),
        color: DeelmarktColors.white,
      ),
      height: DeelCardTokens.listThumbnailSize,
      child: Row(
        children: [
          const SizedBox(
            width: DeelCardTokens.listThumbnailSize,
            height: DeelCardTokens.listThumbnailSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(DeelCardTokens.borderRadius),
                ),
                color: DeelmarktColors.neutral200,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _skeletonBox(width: 60, height: 16),
                  const SizedBox(height: Spacing.s2),
                  _skeletonBox(width: double.infinity, height: 14),
                  const SizedBox(height: Spacing.s1),
                  _skeletonBox(width: 80, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
        color: DeelmarktColors.neutral200,
      ),
    );
  }
}
