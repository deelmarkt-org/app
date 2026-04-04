import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

/// 2-column sliver grid of featured listing cards for category detail.
class FeaturedListingsGrid extends StatelessWidget {
  const FeaturedListingsGrid({
    required this.listings,
    required this.onToggleFavourite,
    super.key,
  });

  final List<ListingEntity> listings;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Spacing.listingCardGap,
          crossAxisSpacing: Spacing.listingCardGap,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final listing = listings[index];
          return DeelCard.grid(
            imageUrl:
                listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
            priceFormatted: Formatters.euroFromCents(listing.priceInCents),
            title: listing.title,
            location: listing.location,
            isFavourited: listing.isFavourited,
            onFavouriteTap: () => onToggleFavourite(listing.id),
            onTap:
                () => context.push(
                  AppRoutes.listingDetail.replaceAll(':id', listing.id),
                ),
          );
        }, childCount: listings.length),
      ),
    );
  }
}
