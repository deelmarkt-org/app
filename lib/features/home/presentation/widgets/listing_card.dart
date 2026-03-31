import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

import 'package:deelmarkt/features/home/presentation/widgets/listing_location_row.dart';

/// Minimum touch target size (44x44) per WCAG / EAA requirements.
const _kTouchTargetSize = 44.0;

/// Listing card for grid display on home and search screens.
///
/// 4:3 image ratio, price (priceSm token), title (max 2 lines),
/// location + distance, and favourite heart overlay.
class ListingCard extends StatelessWidget {
  const ListingCard({
    required this.listing,
    required this.onTap,
    required this.onFavouriteTap,
    super.key,
  });

  final ListingEntity listing;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = Formatters.euroFromCents(listing.priceInCents);
    final distance =
        listing.distanceKm != null
            ? ', ${Formatters.distanceKm(listing.distanceKm!)}'
            : '';

    return Semantics(
      label: '${listing.title}, $price$distance',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImageSection(
                  imageUrl:
                      listing.imageUrls.isNotEmpty
                          ? listing.imageUrls.first
                          : null,
                  isFavourited: listing.isFavourited,
                  onFavouriteTap: onFavouriteTap,
                ),
                Padding(
                  padding: const EdgeInsets.all(Spacing.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(price, style: DeelmarktTypography.priceSm),
                      const SizedBox(height: Spacing.s1),
                      Text(
                        listing.title,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (listing.location != null) ...[
                        const SizedBox(height: Spacing.s1),
                        ListingLocationRow(
                          location: listing.location!,
                          distanceKm: listing.distanceKm,
                        ),
                      ],
                      // TODO(escrow): Add EscrowBadge here when ListingEntity
                      // gains an `isEscrowAvailable` field (E03 Phase 2).
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageUrl,
    required this.isFavourited,
    required this.onFavouriteTap,
  });

  final String? imageUrl;
  final bool isFavourited;
  final VoidCallback onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DeelmarktRadius.xl),
            ),
            // TODO: Replace with CachedNetworkImage when cached_network_image is added (coordinate with team).
            child:
                imageUrl != null
                    ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(context),
                    )
                    : _imagePlaceholder(context),
          ),
          Positioned(
            top: Spacing.s2,
            right: Spacing.s2,
            child: _FavouriteButton(
              isFavourited: isFavourited,
              onTap: onFavouriteTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Icon(
        PhosphorIcons.image(),
        size: DeelmarktIconSize.lg,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourited, required this.onTap});

  final bool isFavourited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          isFavourited
              ? 'listing_card.removeFavourite'.tr()
              : 'listing_card.addFavourite'.tr(),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _kTouchTargetSize,
            height: _kTouchTargetSize,
            child: Icon(
              isFavourited
                  ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                  : PhosphorIcons.heart(),
              color:
                  isFavourited
                      ? DeelmarktColors.error
                      : DeelmarktColors.neutral700,
              size: DeelmarktIconSize.sm,
            ),
          ),
        ),
      ),
    );
  }
}
