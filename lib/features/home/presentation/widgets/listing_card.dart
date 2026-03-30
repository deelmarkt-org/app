import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Listing card for grid display on home and search screens.
///
/// 4:3 image ratio, price, title (max 2 lines), location + distance,
/// escrow badge, and favourite heart overlay.
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

    return Semantics(
      label:
          '${listing.title}, ${Formatters.euroFromCents(listing.priceInCents)}',
      child: GestureDetector(
        onTap: onTap,
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
                    Text(
                      Formatters.euroFromCents(listing.priceInCents),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.s1),
                    Text(
                      listing.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.location != null) ...[
                      const SizedBox(height: Spacing.s1),
                      _LocationRow(
                        location: listing.location!,
                        distanceKm: listing.distanceKm,
                      ),
                    ],
                    const SizedBox(height: Spacing.s1),
                    _EscrowBadge(),
                  ],
                ),
              ),
            ],
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
        size: 32,
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DeelmarktColors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFavourited
                ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                : PhosphorIcons.heart(),
            color:
                isFavourited
                    ? DeelmarktColors.error
                    : DeelmarktColors.neutral700,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location, this.distanceKm});

  final String location;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final text =
        distanceKm != null
            ? '$location · ${distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
            : location;

    return Row(
      children: [
        Icon(
          PhosphorIcons.mapPin(),
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.s1),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EscrowBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          size: 14,
          color: DeelmarktColors.trustVerified,
        ),
        const SizedBox(width: Spacing.s1),
        Text(
          'listing_card.escrowAvailable'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.trustVerified),
        ),
      ],
    );
  }
}
