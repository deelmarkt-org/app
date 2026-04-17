import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_carousel.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';

/// Height of the recent listings horizontal row.
const _recentRowHeight = 280.0;

/// Width of each card in the recent listings row.
const _recentCardWidth = 180.0;

/// Home screen data view — renders categories, trust banner,
/// nearby grid, and recent row.
class HomeDataView extends ConsumerWidget {
  const HomeDataView({required this.data, super.key});

  final HomeState data;

  static int _gridColumns(BuildContext context) {
    if (Breakpoints.isCompact(context)) return 2;
    if (Breakpoints.isMedium(context)) return 3;
    return 4; // expanded
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossAxisCount = _gridColumns(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          _appBar(context),
          if (data.categories.isNotEmpty) _categories(context),
          _trustBanner(),
          _nearbyHeader(context),
          if (data.nearby.isNotEmpty)
            _nearbyGrid(context, ref, crossAxisCount)
          else
            _nearbyEmpty(context),
          if (data.recent.isNotEmpty) ...[
            _recentHeader(context),
            _recentRow(context, ref),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
        ],
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text(
        'app.name'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: [
        const HomeModePillSwitch(),
        const SizedBox(width: Spacing.s2),
        IconButton(
          icon: Icon(PhosphorIcons.heart()),
          tooltip: 'favourites.title'.tr(),
          onPressed: () => context.push(AppRoutes.favourites),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.magnifyingGlass()),
          tooltip: 'nav.search'.tr(),
          onPressed: () => context.go(AppRoutes.search),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.bell()),
          tooltip: 'nav.notifications'.tr(),
          onPressed: null, // Phase 2: wire to notifications (R-34)
        ),
      ],
    );
  }

  Widget _categories(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s4),
        child: CategoryCarousel(
          categories: data.categories,
          onCategoryTap: (cat) {
            context.push('${AppRoutes.categories}/${cat.id}');
          },
        ),
      ),
    );
  }

  Widget _trustBanner() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.s4,
          vertical: Spacing.s4,
        ),
        child: TrustBanner.escrow(),
      ),
    );
  }

  Widget _nearbyHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.s3),
        child: SectionHeader(
          title: 'home.nearby'.tr(),
          actionLabel: 'home.viewAll'.tr(),
          onAction: () => context.go(AppRoutes.search),
        ),
      ),
    );
  }

  Widget _nearbyGrid(BuildContext context, WidgetRef ref, int crossAxisCount) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      sliver: SliverGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Spacing.s3,
        crossAxisSpacing: Spacing.s3,
        childAspectRatio: 0.65,
        children: [
          for (final listing in data.nearby)
            DeelCard.grid(
              imageUrl:
                  listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
              priceInCents: listing.priceInCents,
              originalPriceInCents: listing.originalPriceInCents,
              title: listing.title,
              heroTag: 'listing-${listing.id}',
              location: listing.location,
              distanceFormatted:
                  listing.distanceKm != null
                      ? Formatters.distanceKm(listing.distanceKm!)
                      : null,
              isFavourited: listing.isFavourited,
              onTap:
                  () => context.goNamed(
                    'listing-detail',
                    pathParameters: {'id': listing.id},
                  ),
              onFavouriteTap:
                  () => ref
                      .read(homeNotifierProvider.notifier)
                      .toggleFavourite(listing.id),
            ),
        ],
      ),
    );
  }

  Widget _nearbyEmpty(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyState(
        variant: EmptyStateVariant.search,
        onAction: () => context.go(AppRoutes.search),
      ),
    );
  }

  Widget _recentHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s6, bottom: Spacing.s3),
        child: SectionHeader(
          title: 'home.recentlyAdded'.tr(),
          actionLabel: 'home.viewAll'.tr(),
          onAction: () => context.go(AppRoutes.search),
        ),
      ),
    );
  }

  Widget _recentRow(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: _recentRowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          itemCount: data.recent.length,
          separatorBuilder: (_, _) => const SizedBox(width: Spacing.s3),
          itemBuilder: (context, index) {
            final listing = data.recent[index];
            return SizedBox(
              width: _recentCardWidth,
              child: DeelCard.grid(
                imageUrl:
                    listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                priceInCents: listing.priceInCents,
                originalPriceInCents: listing.originalPriceInCents,
                title: listing.title,
                heroTag: 'listing-${listing.id}',
                location: listing.location,
                distanceFormatted:
                    listing.distanceKm != null
                        ? Formatters.distanceKm(listing.distanceKm!)
                        : null,
                isFavourited: listing.isFavourited,
                onTap:
                    () => context.goNamed(
                      'listing-detail',
                      pathParameters: {'id': listing.id},
                    ),
                onFavouriteTap:
                    () => ref
                        .read(homeNotifierProvider.notifier)
                        .toggleFavourite(listing.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
