import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/favourites_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/favourite_card.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

/// Favourites screen — P-28.
///
/// Displays the user's saved listings in a 2-column grid with
/// optimistic remove + SnackBar undo.
/// Route: `/favourites`
///
/// Reference: docs/screens/03-listings/03-favourites.md
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favouritesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'a11y.back'.tr(),
          child: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft()),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'favourites.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Semantics(
            label: 'favourites.search'.tr(),
            child: IconButton(
              icon: Icon(PhosphorIcons.magnifyingGlass()),
              onPressed: () => context.push(AppRoutes.search),
            ),
          ),
          Semantics(
            label: 'favourites.menu'.tr(),
            child: IconButton(
              icon: Icon(PhosphorIcons.dotsThreeVertical()),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const _LoadingView(),
        error:
            (error, _) => ErrorState(
              onRetry:
                  () => ref.read(favouritesNotifierProvider.notifier).refresh(),
            ),
        data:
            (listings) =>
                listings.isEmpty
                    ? EmptyState.custom(
                      icon: PhosphorIcons.heart(),
                      message: 'favourites.tapHeart'.tr(),
                      actionLabel: 'favourites.discover'.tr(),
                      onAction: () => context.go(AppRoutes.home),
                    )
                    : _DataView(listings: listings),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'a11y.loading'.tr(),
      child: GridView.count(
        padding: const EdgeInsets.all(Spacing.s4),
        crossAxisCount: 2,
        crossAxisSpacing: Spacing.s4,
        mainAxisSpacing: Spacing.s4,
        childAspectRatio: 0.65,
        children: List.generate(6, (_) => const SkeletonListingCard()),
      ),
    );
  }
}

class _DataView extends ConsumerWidget {
  const _DataView({required this.listings});

  final List<ListingEntity> listings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

    return RefreshIndicator(
      onRefresh: () => ref.read(favouritesNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s4,
                Spacing.s4,
                Spacing.s4,
                Spacing.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'favourites.subtitle'.tr().toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    'favourites.savedItems'.tr(),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(Spacing.s4),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: Spacing.s4,
                mainAxisSpacing: Spacing.s4,
                childAspectRatio: 0.65,
              ),
              itemCount: listings.length,
              itemBuilder:
                  (context, index) => FavouriteCard(listing: listings[index]),
            ),
          ),
        ],
      ),
    );
  }
}
