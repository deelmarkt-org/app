import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

/// Location row + map placeholder for the listing detail screen.
///
/// Extracted from [DetailInfoSection] for line-limit compliance.
class DetailLocationBlock extends StatelessWidget {
  const DetailLocationBlock({
    required this.location,
    required this.isDark,
    this.distanceKm,
    super.key,
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
