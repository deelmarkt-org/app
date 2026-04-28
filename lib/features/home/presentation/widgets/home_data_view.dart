import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_carousel.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_buyer_app_bar_actions.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_nearby_section.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_recent_section.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_sliver_app_bar.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

/// Home screen data view — renders categories, trust banner, nearby grid,
/// and recent row. Each section is its own widget so the data view itself
/// is purely a sliver-composition layer.
class HomeDataView extends ConsumerWidget {
  const HomeDataView({required this.data, super.key});

  final HomeState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onToggleFavourite =
        ref.read(homeNotifierProvider.notifier).toggleFavourite;
    return RefreshIndicator(
      onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
      // ResponsiveBody.wide caps the scroll view at Breakpoints.large (1200)
      // on ultra-wide viewports so the grid doesn't stretch edge-to-edge.
      // Each sliver below owns its own horizontal padding (Spacing.s4), so
      // the wrapper's padding is intentionally off (§193 PR A).
      child: ResponsiveBody.wide(
        child: CustomScrollView(
          slivers: [
            const HomeSliverAppBar(extraActions: [HomeBuyerAppBarActions()]),
            if (data.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: Spacing.s4),
                  child: CategoryCarousel(
                    categories: data.categories,
                    onCategoryTap:
                        (cat) =>
                            context.push('${AppRoutes.categories}/${cat.id}'),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.s4,
                  vertical: Spacing.s4,
                ),
                child: TrustBanner.escrow(),
              ),
            ),
            const HomeNearbyHeader(),
            if (data.nearby.isNotEmpty)
              HomeNearbyGrid(
                listings: data.nearby,
                onToggleFavourite: onToggleFavourite,
              )
            else
              const HomeNearbyEmpty(),
            if (data.recent.isNotEmpty) ...[
              const HomeRecentHeader(),
              HomeRecentRow(
                listings: data.recent,
                onToggleFavourite: onToggleFavourite,
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
          ],
        ),
      ),
    );
  }
}
