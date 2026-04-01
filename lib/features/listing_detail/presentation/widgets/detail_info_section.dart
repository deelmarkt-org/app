import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_chips.dart';

/// Price, title, chips, description, own-listing stats, and location
/// with map placeholder. Layout per stitch design.
class DetailInfoSection extends StatefulWidget {
  const DetailInfoSection({
    required this.listing,
    this.categoryName,
    this.isOwnListing = false,
    super.key,
  });

  final ListingEntity listing;
  final String? categoryName;
  final bool isOwnListing;

  @override
  State<DetailInfoSection> createState() => _DetailInfoSectionState();
}

class _DetailInfoSectionState extends State<DetailInfoSection> {
  bool _expanded = false;

  static const int _maxCollapsedLines = 4;
  static const double _mapPlaceholderHeight = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listing = widget.listing;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Price (side by side per design)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.title,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(width: Spacing.s3),
              Text(
                Formatters.euroFromCents(listing.priceInCents),
                style: DeelmarktTypography.price.copyWith(
                  color: DeelmarktColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.s2),

          // Condition + category chips
          Wrap(
            spacing: Spacing.s2,
            runSpacing: Spacing.s1,
            children: [
              ConditionChip(condition: listing.condition),
              if (widget.categoryName != null)
                CategoryChip(name: widget.categoryName!),
            ],
          ),
          const SizedBox(height: Spacing.s4),

          // Description
          Text(
            'listing_detail.description'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          AnimatedCrossFade(
            firstChild: Text(
              listing.description,
              style: theme.textTheme.bodyLarge,
              maxLines: _maxCollapsedLines,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              listing.description,
              style: theme.textTheme.bodyLarge,
            ),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: DeelmarktAnimation.resolve(
              DeelmarktAnimation.standard,
              reduceMotion: reduceMotion,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.s1),
              child: Text(
                _expanded
                    ? 'listing_detail.readLess'.tr()
                    : 'listing_detail.readMore'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DeelmarktColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.s3),

          // Location with map placeholder
          if (listing.location != null) ...[
            Text(
              'listing_detail.locationHeader'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.s2),
            Row(
              children: [
                Icon(
                  PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                  size: DeelmarktIconSize.xs,
                  color: DeelmarktColors.neutral500,
                ),
                const SizedBox(width: Spacing.s1),
                Text(
                  listing.location!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DeelmarktColors.neutral700,
                  ),
                ),
                if (listing.distanceKm != null)
                  Text(
                    ' · ${Formatters.distanceKm(listing.distanceKm!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DeelmarktColors.neutral500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.s3),
            // Map placeholder (per stitch design)
            ClipRRect(
              borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
              child: Container(
                height: _mapPlaceholderHeight,
                width: double.infinity,
                color: DeelmarktColors.neutral100,
                child: Center(
                  child: Icon(
                    PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                    size: DeelmarktIconSize.lg,
                    color: DeelmarktColors.neutral500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
