import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import 'home_notifier.dart';
import 'widgets/category_carousel.dart';
import 'widgets/listing_card.dart';
import 'widgets/section_header.dart';

/// Home screen (buyer mode) — B-50.
///
/// Sections: categories → trust banner → nearby grid → recent row.
/// Route: `/` (root, inside bottom nav shell).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return homeState.when(
      loading: () => _LoadingView(),
      error:
          (error, _) => ErrorState(
            onRetry: () => ref.read(homeNotifierProvider.notifier).refresh(),
          ),
      data: (data) => _DataView(data: data),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Breakpoints.isCompact(context) ? 2 : 3;

    return Semantics(
      label: 'a11y.loading'.tr(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(Spacing.s4),
            sliver: SliverGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: Spacing.s3,
              crossAxisSpacing: Spacing.s3,
              childAspectRatio: 0.7,
              children: List.generate(6, (_) => const SkeletonListingCard()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataView extends ConsumerWidget {
  const _DataView({required this.data});

  final HomeState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossAxisCount = Breakpoints.isCompact(context) ? 2 : 3;

    return RefreshIndicator(
      onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            title: Text(
              'app.name'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(PhosphorIcons.magnifyingGlass()),
                tooltip: 'nav.search'.tr(),
                onPressed: () => context.go(AppRoutes.search),
              ),
            ],
          ),

          // Categories
          if (data.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.s4),
                child: CategoryCarousel(
                  categories: data.categories,
                  onCategoryTap: (cat) {
                    context.go('${AppRoutes.search}?category=${cat.id}');
                  },
                ),
              ),
            ),

          // Trust banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s4,
                vertical: Spacing.s4,
              ),
              child: const EscrowTrustBanner(),
            ),
          ),

          // Nearby section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.s3),
              child: SectionHeader(
                title: 'home.nearby'.tr(),
                actionLabel: 'home.viewAll'.tr(),
                onAction: () => context.go(AppRoutes.search),
              ),
            ),
          ),

          // Nearby listings grid
          if (data.nearby.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
              sliver: SliverGrid.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: Spacing.s3,
                crossAxisSpacing: Spacing.s3,
                childAspectRatio: 0.65,
                children: [
                  for (final listing in data.nearby)
                    ListingCard(
                      listing: listing,
                      onTap: () => context.go('/listings/${listing.id}'),
                      onFavouriteTap:
                          () => ref
                              .read(homeNotifierProvider.notifier)
                              .toggleFavourite(listing.id),
                    ),
                ],
              ),
            ),

          // Recently added header
          if (data.recent.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.s6,
                  bottom: Spacing.s3,
                ),
                child: SectionHeader(
                  title: 'home.recentlyAdded'.tr(),
                  actionLabel: 'home.viewAll'.tr(),
                  onAction: () => context.go(AppRoutes.search),
                ),
              ),
            ),

          // Recent listings horizontal row
          if (data.recent.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
                  itemCount: data.recent.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Spacing.s3),
                  itemBuilder: (context, index) {
                    final listing = data.recent[index];
                    return SizedBox(
                      width: 180,
                      child: ListingCard(
                        listing: listing,
                        onTap: () => context.go('/listings/${listing.id}'),
                        onFavouriteTap:
                            () => ref
                                .read(homeNotifierProvider.notifier)
                                .toggleFavourite(listing.id),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
        ],
      ),
    );
  }
}
