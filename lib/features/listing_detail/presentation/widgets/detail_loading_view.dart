import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Full-page skeleton loading view for listing detail.
///
/// Matches the stitch design in `product_detail_loading_state/screen.png`:
/// image block, title/price row, chip placeholders, description lines,
/// seller card placeholder, and action bar.
///
/// Per P-54 PR-D: this previously carried a bespoke `_bone()` helper +
/// `boneColor` plumbing through 5 sub-widgets — now consumes the shared
/// `SkeletonBox` primitive (`lib/widgets/feedback/skeleton_shapes.dart`)
/// which is theme-aware and removes ~75 LOC of duplicated infrastructure.
class DetailLoadingView extends StatelessWidget {
  const DetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: 'a11y.loading'.tr(),
          child: const SkeletonLoader(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: SkeletonBox(borderRadius: 0),
                        ),
                        _ContentSkeleton(),
                      ],
                    ),
                  ),
                ),
                _ActionBarSkeleton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentSkeleton extends StatelessWidget {
  const _ContentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 56, borderRadius: DeelmarktRadius.sm),
          SizedBox(height: Spacing.s4),
          Row(
            children: [
              Expanded(
                child: SkeletonBox(
                  height: 24,
                  borderRadius: DeelmarktRadius.sm,
                ),
              ),
              SizedBox(width: Spacing.s4),
              SkeletonBox(
                width: 80,
                height: 24,
                borderRadius: DeelmarktRadius.sm,
              ),
            ],
          ),
          SizedBox(height: Spacing.s3),
          Row(
            children: [
              SkeletonBox(
                width: 72,
                height: 24,
                borderRadius: DeelmarktRadius.full,
              ),
              SizedBox(width: Spacing.s2),
              SkeletonBox(
                width: 64,
                height: 24,
                borderRadius: DeelmarktRadius.full,
              ),
            ],
          ),
          SizedBox(height: Spacing.s4),
          SkeletonBox(height: 14, borderRadius: DeelmarktRadius.xs),
          SizedBox(height: Spacing.s2),
          SkeletonBox(height: 14, borderRadius: DeelmarktRadius.xs),
          SizedBox(height: Spacing.s2),
          SkeletonBox(width: 200, height: 14, borderRadius: DeelmarktRadius.xs),
          SizedBox(height: Spacing.s6),
          _SellerCardSkeleton(),
        ],
      ),
    );
  }
}

class _SellerCardSkeleton extends StatelessWidget {
  const _SellerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: DeelmarktRadius.full,
          ),
          SizedBox(width: Spacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 120,
                  height: 16,
                  borderRadius: DeelmarktRadius.xs,
                ),
                SizedBox(height: Spacing.s2),
                SkeletonBox(
                  width: 80,
                  height: 12,
                  borderRadius: DeelmarktRadius.xs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBarSkeleton extends StatelessWidget {
  const _ActionBarSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: SkeletonBox(height: 52, borderRadius: DeelmarktRadius.lg),
          ),
          SizedBox(width: Spacing.s3),
          Expanded(
            child: SkeletonBox(height: 52, borderRadius: DeelmarktRadius.lg),
          ),
        ],
      ),
    );
  }
}
