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
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final listing = widget.listing;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final accentColor =
        isDark ? DeelmarktColors.darkSecondary : DeelmarktColors.secondary;

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
              Text(
                Formatters.euroFromCents(listing.priceInCents),
                style: DeelmarktTypography.price.copyWith(
                  color:
                      isDark
                          ? DeelmarktColors.darkPrimary
                          : DeelmarktColors.primary,
                ),
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
          const SizedBox(height: Spacing.s3),
          if (listing.location != null)
            _LocationBlock(
              location: listing.location!,
              distanceKm: listing.distanceKm,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

/// Location row + map placeholder, extracted for line-limit compliance.
class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.location,
    required this.isDark,
    this.distanceKm,
  });

  final String location;
  final double? distanceKm;
  final bool isDark;

  static const double _mapPlaceholderHeight = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

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
        Row(
          children: [
            Icon(
              PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
              size: DeelmarktIconSize.xs,
              color: mutedColor,
            ),
            const SizedBox(width: Spacing.s1),
            Text(
              location,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurface
                        : DeelmarktColors.neutral700,
              ),
            ),
            if (distanceKm != null)
              Text(
                ' · ${Formatters.distanceKm(distanceKm!)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
              ),
          ],
        ),
        const SizedBox(height: Spacing.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          child: Container(
            height: _mapPlaceholderHeight,
            width: double.infinity,
            color:
                isDark
                    ? DeelmarktColors.darkSurfaceElevated
                    : DeelmarktColors.neutral100,
            child: Center(
              child: Icon(
                PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                size: DeelmarktIconSize.lg,
                color: mutedColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
