import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

/// Pin icon size for the detail variant.
const double kPinDetail = 18;

/// Pin icon size for the map placeholder.
const double kPinMapPlaceholder = 32;

/// Detail variant of [LocationBadge]: pin (18 px) + `headlineSmall` city +
/// `bodyMedium` distance subtitle, optionally with a 16:9 map placeholder.
class LocationBadgeDetail extends StatelessWidget {
  const LocationBadgeDetail({
    required this.city,
    required this.distanceKm,
    required this.showMapPlaceholder,
    super.key,
  });

  final String city;
  final double? distanceKm;
  final bool showMapPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.mapPin(), size: kPinDetail, color: onSurface),
            const SizedBox(width: Spacing.s2),
            Expanded(
              child: Text(
                city,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (distanceKm != null) ...[
          const SizedBox(height: Spacing.s1),
          Padding(
            padding: const EdgeInsets.only(left: kPinDetail + Spacing.s2),
            child: Text(
              Formatters.distanceKm(distanceKm!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (showMapPlaceholder) ...[
          const SizedBox(height: Spacing.s3),
          const LocationMapPlaceholder(),
        ],
      ],
    );
  }
}

/// Neutral 16:9 map placeholder with centred pin icon. Real map is B-31.
class LocationMapPlaceholder extends StatelessWidget {
  const LocationMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'location_badge.mapPlaceholder'.tr(),
      image: true,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.mapPin(),
              size: kPinMapPlaceholder,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
