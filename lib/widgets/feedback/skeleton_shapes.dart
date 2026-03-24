import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';

/// A rectangular shimmer placeholder for text lines.
///
/// Pure visual — no animation logic. Must be placed inside a [SkeletonLoader]
/// for the shimmer effect to cascade into this widget.
///
/// Reference: docs/design-system/components.md §Loading — Shimmer Skeletons
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = DeelmarktRadius.xs,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fillColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

/// A circular shimmer placeholder for avatars.
///
/// Pure visual — must be inside a [SkeletonLoader] for animation.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fillColor(context),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

/// A rectangular shimmer placeholder for images.
///
/// Pure visual — must be inside a [SkeletonLoader] for animation.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = DeelmarktRadius.md,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fillColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

/// Theme-aware fill color for skeleton shapes.
Color _fillColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? DeelmarktColors.darkSurfaceElevated
      : DeelmarktColors.neutral200;
}
