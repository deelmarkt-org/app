import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/location/location_badge_detail.dart';
import 'package:deelmarkt/widgets/location/location_badge_skeleton.dart';

/// Visual density for a [LocationBadge].
enum LocationBadgeVariant {
  /// Card usage: pin (14 px) + `{city} · {distance}` on a single line.
  compact,

  /// Listing-detail usage: pin (18 px) + headlineSmall city + bodyMedium
  /// distance subtitle, optionally with a 16:9 map placeholder.
  detail,

  /// Shimmer placeholder — use via [LocationBadge.skeletonCompact].
  /// Models the compact layout only.
  skeleton,
}

/// Minimum touch target (WCAG 2.2 AA / CLAUDE.md §10).
const double _kMinTapTarget = 44;

/// Pin icon size for the compact variant.
const double _kPinCompact = 14;

/// Shared widget for location display.
///
/// Exposes pin + city + optional distance in three visual densities:
/// compact (card), detail (screen), skeleton (loading).
///
/// **GDPR note**: this widget deliberately does NOT accept a postal
/// code parameter. Postal code + city + distance can triangulate a
/// seller's home within ~100 m; combined with the scam surface of
/// listings, that is unjustified under AVG/GDPR Art. 5(1)(c).
///
/// Reference:
/// - `docs/design-system/components.md` §LocationBadge
/// - `docs/design-system/patterns.md` §Listing Detail
class LocationBadge extends StatelessWidget {
  const LocationBadge({
    required this.city,
    this.distanceKm,
    this.variant = LocationBadgeVariant.compact,
    this.showMapPlaceholder = false,
    this.onTap,
    super.key,
  });

  /// Compact loading placeholder. Named `skeletonCompact` to make clear
  /// the skeleton only models the compact layout.
  const LocationBadge.skeletonCompact({super.key})
    : city = '',
      distanceKm = null,
      variant = LocationBadgeVariant.skeleton,
      showMapPlaceholder = false,
      onTap = null;

  final String city;
  final double? distanceKm;
  final LocationBadgeVariant variant;

  /// Detail-variant only. When true, renders a neutral 16:9 placeholder
  /// rectangle with a centred pin icon. Real map work lives in B-31.
  final bool showMapPlaceholder;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (variant == LocationBadgeVariant.skeleton) {
      return const LocationBadgeSkeleton();
    }

    final content =
        variant == LocationBadgeVariant.detail
            ? LocationBadgeDetail(
              city: city,
              distanceKm: distanceKm,
              showMapPlaceholder: showMapPlaceholder,
            )
            : _CompactContent(city: city, distanceKm: distanceKm);

    final body = Semantics(
      label: _semanticsLabel(),
      button: onTap != null,
      excludeSemantics: true,
      child: content,
    );

    if (onTap == null) return body;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _kMinTapTarget,
        minWidth: _kMinTapTarget,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          child: body,
        ),
      ),
    );
  }

  String _semanticsLabel() {
    if (distanceKm != null) {
      return 'location_badge.a11yWithDistance'.tr(
        namedArgs: {
          'city': city,
          'distance': Formatters.distanceKm(distanceKm!),
        },
      );
    }
    return 'location_badge.a11yCityOnly'.tr(namedArgs: {'city': city});
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.city, required this.distanceKm});
  final String city;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final text =
        distanceKm != null
            ? '$city · ${Formatters.distanceKm(distanceKm!)}'
            : city;
    return Row(
      children: [
        Icon(
          PhosphorIcons.mapPin(),
          size: _kPinCompact,
          color: onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.s1),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
