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

/// Price, condition chip, title, description (expandable), category,
/// and location row. Layout matches stitch design:
/// Title (left) + Price (right-aligned), condition chip below.
class DetailInfoSection extends StatefulWidget {
  const DetailInfoSection({
    required this.listing,
    this.categoryName,
    super.key,
  });

  final ListingEntity listing;
  final String? categoryName;

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

          // Condition chip + category
          Wrap(
            spacing: Spacing.s2,
            runSpacing: Spacing.s1,
            children: [
              _ConditionChip(condition: listing.condition),
              if (widget.categoryName != null)
                _CategoryChip(name: widget.categoryName!),
            ],
          ),
          const SizedBox(height: Spacing.s4),

          // Description header
          Text(
            'listing_detail.description'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.s1),

          // Description body (expandable, respects reduced motion)
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

          // Location section with header
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
          ],
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.condition});

  final ListingCondition condition;

  @override
  Widget build(BuildContext context) {
    final label = 'condition.${condition.name}'.tr();
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s2,
          vertical: Spacing.s1,
        ),
        decoration: BoxDecoration(
          color: DeelmarktColors.neutral100,
          borderRadius: BorderRadius.circular(DeelmarktRadius.full),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.neutral700),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: DeelmarktColors.secondarySurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.secondary),
      ),
    );
  }
}
