import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Pin icon size matching the compact variant.
const double _kPinCompact = 14;

/// Height of the shimmer line placeholder.
const double kSkeletonLineHeight = 12;

/// Compact skeleton placeholder for [LocationBadge].
///
/// Renders inside a [SkeletonLoader] so the ambient shimmer sweep cascades.
/// Announces "loading" to screen readers via `Semantics(liveRegion: true)`.
class LocationBadgeSkeleton extends StatelessWidget {
  const LocationBadgeSkeleton({super.key});

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
            Expanded(child: SkeletonLine(height: kSkeletonLineHeight)),
          ],
        ),
      ),
    );
  }
}
