import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Grey overlay with "VERKOCHT" badge for sold listings.
///
/// Wraps the image gallery. Applies a desaturated colour filter
/// and centres a bold badge.
class SoldOverlay extends StatelessWidget {
  const SoldOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s6,
                vertical: Spacing.s3,
              ),
              decoration: BoxDecoration(
                // neutral900 at 70% opacity is intentionally theme-invariant:
                // the badge is a dark scrim rendered on top of the greyscale
                // image, not on the scaffold surface. White text on this scrim
                // yields 15.7:1 contrast — correct in both light and dark mode.
                color: DeelmarktColors.neutral900.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
              ),
              child: Text(
                'listing_detail.soldBadge'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  // White on neutral900@70% → 15.7:1 (AAA). Do NOT change to
                  // colorScheme.onSurface — that would break dark mode contrast.
                  color: DeelmarktColors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
