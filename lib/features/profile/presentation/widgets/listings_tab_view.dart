import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/cards/deel_card_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Adaptive grid of user's listings with status badges.
///
/// Uses [AdaptiveListingGrid] (2→3→4 columns) instead of a hardcoded
/// 2-column delegate so the profile screen benefits from the wider
/// 900px container on expanded viewports (issue #196).
///
/// The grid is a self-scrolling [CustomScrollView] — host it inside a
/// widget that provides bounded height (e.g. `TabBarView` inside
/// `NestedScrollView` body, or `SliverFillRemaining` body). Do NOT
/// wrap in another scrollable; the grid coordinates its own scroll.
class ListingsTabView extends StatelessWidget {
  const ListingsTabView({
    required this.listings,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<ListingEntity>> listings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return listings.when(
      loading: _buildLoadingGrid,
      error:
          (_, _) => ErrorState(message: 'error.generic'.tr(), onRetry: onRetry),
      data: (items) => _buildDataGrid(context, items),
    );
  }

  Widget _buildLoadingGrid() {
    return CustomScrollView(
      slivers: [
        AdaptiveListingGrid(
          itemCount: 4,
          itemBuilder: (_, _) => const DeelCardSkeleton(),
        ),
      ],
    );
  }

  Widget _buildDataGrid(BuildContext context, List<ListingEntity> items) {
    if (items.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.myListings,
        onAction: () {
          StatefulNavigationShell.of(context).goBranch(AppRoutes.sellTabIndex);
        },
      );
    }

    return CustomScrollView(
      slivers: [
        AdaptiveListingGrid(
          itemCount: items.length,
          itemBuilder: (context, index) => _buildCard(context, items[index]),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ListingEntity listing) {
    return Semantics(
      button: true,
      label:
          '${'listing.price'.tr()} ${Formatters.euroFromCents(listing.priceInCents)}, ${listing.title}',
      child: DeelCard.grid(
        imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
        priceInCents: listing.priceInCents,
        originalPriceInCents: listing.originalPriceInCents,
        title: listing.title,
        onTap: () {
          context.pushNamed(
            'listing-detail',
            pathParameters: {'id': listing.id},
          );
        },
        location: listing.location,
      ),
    );
  }
}
