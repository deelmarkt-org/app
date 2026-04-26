import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

/// Listing card rendered inside the category detail's featured grid.
///
/// **Behaviour vs the former in-screen `FeaturedListingsGrid`:** distance is
/// shown when [ListingEntity.distanceKm] is non-null. The former widget
/// omitted `distanceFormatted` entirely — this aligns the card with every
/// other listing card in the app (#210 H2). Reverted only if the product
/// decision is to keep category-detail cards distance-free.
class CategoryFeaturedListingCard extends StatelessWidget {
  const CategoryFeaturedListingCard({
    required this.listing,
    required this.onToggleFavourite,
    super.key,
  });

  final ListingEntity listing;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return DeelCard.grid(
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      priceInCents: listing.priceInCents,
      originalPriceInCents: listing.originalPriceInCents,
      title: listing.title,
      location: listing.location,
      distanceFormatted:
          listing.distanceKm != null
              ? Formatters.distanceKm(listing.distanceKm!)
              : null,
      isFavourited: listing.isFavourited,
      onFavouriteTap: () => onToggleFavourite(listing.id),
      onTap:
          () => context.push(
            AppRoutes.listingDetail.replaceAll(':id', listing.id),
          ),
    );
  }
}
