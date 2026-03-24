import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Shimmer loading wrapper. Wraps a widget tree with a left-to-right
/// shimmer sweep animation (1500ms loop).
///
/// Use this at the **composite level** (e.g., wrapping an entire skeleton card),
/// not around individual shapes. The shimmer effect cascades to all
/// [DecoratedBox] children automatically — one [AnimationController] per
/// [SkeletonLoader] instance.
///
/// Respects `MediaQuery.disableAnimations` (WCAG 2.2 §2.3.3).
///
/// Reference: docs/design-system/components.md §Loading — Shimmer Skeletons
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({required this.child, this.enabled = true, super.key});

  /// The widget tree to apply the shimmer effect to.
  final Widget child;

  /// Whether the shimmer animation is active. Defaults to `true`.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'a11y.loading'.tr(),
      child: Shimmer.fromColors(
        baseColor:
            isDark
                ? DeelmarktColors.darkSurfaceElevated
                : DeelmarktColors.neutral200,
        highlightColor:
            isDark
                ? DeelmarktColors.darkShimmerHighlight
                : DeelmarktColors.neutral100,
        period: const Duration(milliseconds: 1500),
        enabled: enabled && !reduceMotion,
        child: child,
      ),
    );
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
