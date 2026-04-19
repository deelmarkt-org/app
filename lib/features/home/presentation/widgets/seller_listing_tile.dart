import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Seller listing tile — list row showing thumbnail, title, price,
/// views/favs, days active, and status badge.
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class SellerListingTile extends StatelessWidget {
  const SellerListingTile({
    required this.listing,
    required this.onTap,
    super.key,
  });

  final ListingEntity listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: listing.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s4,
            vertical: Spacing.s3,
          ),
          child: Row(
            children: [
              _thumbnail(isDark),
              const SizedBox(width: Spacing.s3),
              _infoColumn(context, isDark),
              _StatusBadge(status: listing.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
      child: SizedBox(
        width: 56,
        height: 56,
        child:
            listing.imageUrls.isNotEmpty
                ? Image.network(
                  listing.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(isDark),
                )
                : _placeholder(isDark),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, bool isDark) {
    final subtitleColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final daysActive = DateTime.now().difference(listing.createdAt).inDays;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            listing.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            Formatters.euroFromCents(listing.priceInCents),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: DeelmarktColors.primary,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          _statsRow(context, subtitleColor, daysActive),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, Color subtitleColor, int daysActive) {
    return Semantics(
      label: 'a11y.listing_stats'.tr(
        namedArgs: {
          'views': '${listing.viewCount}',
          'favourites': '${listing.favouriteCount}',
          'days': '$daysActive',
        },
      ),
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(PhosphorIcons.eye(), size: 14, color: subtitleColor),
          const SizedBox(width: Spacing.s1),
          Text(
            '${listing.viewCount}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: subtitleColor),
          ),
          const SizedBox(width: Spacing.s3),
          Icon(PhosphorIcons.heart(), size: 14, color: subtitleColor),
          const SizedBox(width: Spacing.s1),
          Text(
            '${listing.favouriteCount}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: subtitleColor),
          ),
          const SizedBox(width: Spacing.s3),
          Text(
            'home.seller.daysActive'.tr(args: [daysActive.toString()]),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral100,
      child: Icon(
        PhosphorIcons.image(),
        color:
            isDark
                ? DeelmarktColors.darkOnSurfaceSecondary
                : DeelmarktColors.neutral300,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      ListingStatus.active => (
        'listing.status.active'.tr(),
        DeelmarktColors.successSurface,
        DeelmarktColors.success,
      ),
      ListingStatus.sold => (
        'listing.status.sold'.tr(),
        DeelmarktColors.primarySurface,
        DeelmarktColors.primary,
      ),
      ListingStatus.draft => (
        'listing.status.draft'.tr(),
        DeelmarktColors.neutral100,
        DeelmarktColors.neutral500,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
