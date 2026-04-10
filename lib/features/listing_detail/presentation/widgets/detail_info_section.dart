import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/price/price_tag.dart';

import 'package:deelmarkt/widgets/location/location_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listing = widget.listing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              PriceTag(
                priceInCents: listing.priceInCents,
                originalPriceInCents: listing.originalPriceInCents,
              ),
            ],
          ),
          const SizedBox(height: Spacing.s2),
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
          Text(
            'listing_detail.description'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          _buildDescriptionBlock(context),
          const SizedBox(height: Spacing.s3),
          if (listing.location != null)
            _buildLocationBlock(context, listing.location!, listing.distanceKm),
        ],
      ),
    );
  }

  Widget _buildDescriptionBlock(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final accentColor =
        isDark ? DeelmarktColors.darkSecondary : DeelmarktColors.secondary;
    final description = widget.listing.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            description,
            style: theme.textTheme.bodyLarge,
            maxLines: _maxCollapsedLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(description, style: theme.textTheme.bodyLarge),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: DeelmarktAnimation.resolve(
            DeelmarktAnimation.standard,
            reduceMotion: reduceMotion,
          ),
        ),
        Semantics(
          button: true,
          label:
              _expanded
                  ? 'listing_detail.readLess'.tr()
                  : 'listing_detail.readMore'.tr(),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _expanded
                      ? 'listing_detail.readLess'.tr()
                      : 'listing_detail.readMore'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBlock(
    BuildContext context,
    String city,
    double? distanceKm,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'listing_detail.locationHeader'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        LocationBadge(
          city: city,
          distanceKm: distanceKm,
          variant: LocationBadgeVariant.detail,
          showMapPlaceholder: true,
        ),
      ],
    );
  }
}
