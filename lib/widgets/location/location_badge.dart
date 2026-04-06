import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Visual density for a [LocationBadge].
enum LocationBadgeVariant {
  /// Card usage: pin (14 px) + `{city} · {distance}` on a single line in
  /// `bodySmall` / `onSurfaceVariant`. Matches the legacy `ListingLocationRow`.
  compact,

  /// Listing-detail usage: pin (18 px) + `headlineSmall` city + `bodyMedium`
  /// distance subtitle, optionally followed by a placeholder map rect.
  detail,

  /// Shimmer placeholder — use via [LocationBadge.skeletonCompact].
  /// Models the compact layout only.
  skeleton,
}

/// Minimum touch target (WCAG 2.2 AA / CLAUDE.md §10).
const double _kMinTapTarget = 44;

/// Pin icon sizes per variant.
const double _kPinCompact = 14;
const double _kPinDetail = 18;
const double _kPinMapPlaceholder = 32;

/// Shared widget replacing the feature-local `ListingLocationRow`.
///
/// Exposes pin + city + optional distance in three visual densities:
/// compact (card), detail (screen), skeleton (loading).
///
/// **GDPR note**: this widget deliberately does NOT accept a postal
/// code parameter. Postal code + city + distance can triangulate a
/// seller's home within ~100 m; combined with the scam surface of
/// listings, that is unjustified under AVG/GDPR Art. 5(1)(c) (data
/// minimisation). If a legitimate a11y or mapping use case ever
/// appears, add the field together with a test that asserts it never
/// reaches a visible surface (Text, Tooltip, or Semantics label).
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

  /// Compact loading placeholder. Renders inside a [SkeletonLoader] so the
  /// ambient shimmer sweep cascades into the shapes. Named `skeletonCompact`
  /// to make clear the skeleton only models the compact layout.
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
      return const _LocationBadgeSkeleton();
    }

    final content =
        variant == LocationBadgeVariant.detail
            ? _DetailContent(
              city: city,
              distanceKm: distanceKm,
              showMapPlaceholder: showMapPlaceholder,
            )
            : _CompactContent(city: city, distanceKm: distanceKm);

    final semanticLabel = _semanticsLabel();

    final body = Semantics(
      label: semanticLabel,
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

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.city,
    required this.distanceKm,
    required this.showMapPlaceholder,
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
            Icon(PhosphorIcons.mapPin(), size: _kPinDetail, color: onSurface),
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
            padding: const EdgeInsets.only(left: _kPinDetail + Spacing.s2),
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
          const _MapPlaceholder(),
        ],
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

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
              size: _kPinMapPlaceholder,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationBadgeSkeleton extends StatelessWidget {
  const _LocationBadgeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'a11y.loading'.tr(),
      liveRegion: true,
      child: const SkeletonLoader(
        child: Row(
          children: [
            SkeletonCircle(size: _kPinCompact),
            SizedBox(width: Spacing.s1),
            Expanded(child: SkeletonLine(height: 12)),
          ],
        ),
      ),
    );
  }
}
