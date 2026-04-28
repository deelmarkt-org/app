import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/escrow_aware_listing_card.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

/// "Nearby" header sliver for the buyer home view.
///
/// Pure presentational — the parent decides whether to render the grid
/// ([HomeNearbyGrid]) or the empty state ([HomeNearbyEmpty]) below.
class HomeNearbyHeader extends StatelessWidget {
  const HomeNearbyHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Adaptive grid of "nearby" listings on the buyer home view.
///
/// Each card delegates favourite toggling and tap navigation back to the
/// parent so the data view stays the only Riverpod-aware layer.
class HomeNearbyGrid extends StatelessWidget {
  const HomeNearbyGrid({
    required this.listings,
    required this.onToggleFavourite,
    super.key,
  });

  final List<ListingEntity> listings;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListingGrid(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return EscrowAwareListingCard(
          listing: listing,
          onTap:
              () => context.goNamed(
                'listing-detail',
                pathParameters: {'id': listing.id},
              ),
          onFavouriteTap: () => onToggleFavourite(listing.id),
        );
      },
    );
  }
}

/// Empty-state filler shown when there are no nearby listings.
class HomeNearbyEmpty extends StatelessWidget {
  const HomeNearbyEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyState(
        variant: EmptyStateVariant.search,
        onAction: () => context.go(AppRoutes.search),
      ),
    );
  }
}
