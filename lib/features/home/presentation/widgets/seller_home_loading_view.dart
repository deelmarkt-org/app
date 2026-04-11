import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Loading skeleton for seller home — toggle + shimmer skeletons
/// for greeting, stats, and listings.
///
/// Reference: docs/screens/02-home/designs/home_loading_state/
class SellerHomeLoadingView extends StatelessWidget {
  const SellerHomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'a11y.loading'.tr(),
      child: CustomScrollView(
        slivers: [
          _appBar(context),
          SliverToBoxAdapter(
            child: SkeletonLoader(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 200, height: 28),
                    const SizedBox(height: Spacing.s6),
                    _statsRowSkeleton(),
                    const SizedBox(height: Spacing.s8),
                    const SkeletonLine(width: 120, height: 20),
                    const SizedBox(height: Spacing.s4),
                    ..._listingSkeletons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _appBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text(
        'app.name'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: const [HomeModePillSwitch(), SizedBox(width: Spacing.s3)],
    );
  }

  Widget _statsRowSkeleton() {
    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(right: Spacing.s3),
            child: SkeletonBox(width: 140, height: 100),
          ),
        ),
      ),
    );
  }

  List<Widget> _listingSkeletons() {
    return List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: Spacing.s3),
        child: Row(
          children: [
            SkeletonBox(width: 56, height: 56),
            SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 160),
                  SizedBox(height: Spacing.s2),
                  SkeletonLine(width: 80, height: 14),
                  SizedBox(height: Spacing.s2),
                  SkeletonLine(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
