import 'package:flutter/material.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

/// Builds a [DeelCard.grid] from a [ListingEntity] with the canonical
/// parameter mapping used across listing surfaces (home, search, categories).
///
/// Centralises the entity→card translation so call sites only supply the
/// feature-specific callbacks and optional overrides. Eliminates the repeated
/// 8-parameter block that would otherwise appear in every listing surface.
Widget listingDeelCard(
  ListingEntity listing, {
  required VoidCallback onTap,
  required VoidCallback onFavouriteTap,
  bool showEscrowBadge = false,
}) => DeelCard.grid(
  imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
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
  showEscrowBadge: showEscrowBadge,
  onTap: onTap,
  onFavouriteTap: onFavouriteTap,
);
