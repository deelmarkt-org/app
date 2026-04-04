import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
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

  /// Shimmer placeholder — use via [LocationBadge.skeleton].
  skeleton,
}

/// Minimum touch target (WCAG 2.2 AA / CLAUDE.md §10).
const double _kMinTapTarget = 44;

/// Pin icon sizes per variant.
const double _kPinCompact = 14;
const double _kPinDetail = 18;

/// Shared shared-widget replacing `ListingLocationRow`.
///
/// Exposes pin + city + optional distance in three visual densities:
/// compact (card), detail (screen), skeleton (loading). `postalCode` is
/// accepted for screen-reader context only and is NEVER rendered in the UI
/// to respect GDPR (PII minimisation in scam-adjacent surfaces).
///
/// Reference:
/// - `docs/design-system/components.md` §LocationBadge
/// - `docs/design-system/patterns.md` §Listing Detail
class LocationBadge extends StatelessWidget {
  const LocationBadge({
    required this.city,
    this.distanceKm,
    this.postalCode,
    this.variant = LocationBadgeVariant.compact,
    this.showMapPlaceholder = false,
    this.onTap,
    super.key,
  }) : _isSkeleton = false;

  /// Loading placeholder. Renders inside a [SkeletonLoader] so the ambient
  /// shimmer sweep cascades into the shapes.
  const LocationBadge.skeleton({super.key})
    : city = '',
      distanceKm = null,
      postalCode = null,
      variant = LocationBadgeVariant.skeleton,
      showMapPlaceholder = false,
      onTap = null,
      _isSkeleton = true;

  final String city;
  final double? distanceKm;

  /// Accessibility-only context. Never rendered as text (GDPR / scam risk).
  final String? postalCode;

  final LocationBadgeVariant variant;

  /// Detail-variant only. When true, renders a neutral 16:9 placeholder
  /// rectangle with a centred pin icon. Real map work lives in B-31.
  final bool showMapPlaceholder;

  final VoidCallback? onTap;

  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton || variant == LocationBadgeVariant.skeleton) {
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
      constraints: const BoxConstraints(minHeight: _kMinTapTarget),
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
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DeelmarktColors.darkSurfaceElevated
                    : DeelmarktColors.neutral100,
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.mapPin(),
              size: 32,
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
    return const SkeletonLoader(
      child: Row(
        children: [
          SkeletonCircle(size: _kPinCompact),
          SizedBox(width: Spacing.s1),
          Expanded(child: SkeletonLine(height: 12)),
        ],
      ),
    );
  }
}
