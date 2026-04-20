import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// Full-page skeleton loading view for listing detail.
///
/// Matches the stitch design in `product_detail_loading_state/screen.png`:
/// image block, title/price row, chip placeholders, description lines,
/// seller card placeholder, and action bar.
class DetailLoadingView extends StatelessWidget {
  const DetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral200;
    final borderColor =
        isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200;

    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: 'a11y.loading'.tr(),
          child: SkeletonLoader(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: boneColor),
                          ),
                        ),
                        _ContentSkeleton(
                          boneColor: boneColor,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                  ),
                ),
                _ActionBarSkeleton(
                  boneColor: boneColor,
                  borderColor: borderColor,
                  surfaceColor: theme.colorScheme.surface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentSkeleton extends StatelessWidget {
  const _ContentSkeleton({required this.boneColor, required this.borderColor});

  final Color boneColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(double.infinity, 56, DeelmarktRadius.sm, boneColor),
          const SizedBox(height: Spacing.s4),
          _TitlePriceRow(boneColor: boneColor),
          const SizedBox(height: Spacing.s3),
          _ChipsRow(boneColor: boneColor),
          const SizedBox(height: Spacing.s4),
          _DescriptionLines(boneColor: boneColor),
          const SizedBox(height: Spacing.s6),
          _SellerCardSkeleton(boneColor: boneColor, borderColor: borderColor),
        ],
      ),
    );
  }
}

class _TitlePriceRow extends StatelessWidget {
  const _TitlePriceRow({required this.boneColor});
  final Color boneColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _bone(double.infinity, 24, DeelmarktRadius.sm, boneColor),
      ),
      const SizedBox(width: Spacing.s4),
      _bone(80, 24, DeelmarktRadius.sm, boneColor),
    ],
  );
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.boneColor});
  final Color boneColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _bone(72, 24, DeelmarktRadius.full, boneColor),
      const SizedBox(width: Spacing.s2),
      _bone(64, 24, DeelmarktRadius.full, boneColor),
    ],
  );
}

class _DescriptionLines extends StatelessWidget {
  const _DescriptionLines({required this.boneColor});
  final Color boneColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _bone(double.infinity, 14, DeelmarktRadius.xs, boneColor),
      const SizedBox(height: Spacing.s2),
      _bone(double.infinity, 14, DeelmarktRadius.xs, boneColor),
      const SizedBox(height: Spacing.s2),
      _bone(200, 14, DeelmarktRadius.xs, boneColor),
    ],
  );
}

class _SellerCardSkeleton extends StatelessWidget {
  const _SellerCardSkeleton({
    required this.boneColor,
    required this.borderColor,
  });

  final Color boneColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.s4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      children: [
        _bone(48, 48, DeelmarktRadius.full, boneColor),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bone(120, 16, DeelmarktRadius.xs, boneColor),
              const SizedBox(height: Spacing.s2),
              _bone(80, 12, DeelmarktRadius.xs, boneColor),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionBarSkeleton extends StatelessWidget {
  const _ActionBarSkeleton({
    required this.boneColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  final Color boneColor;
  final Color borderColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _bone(double.infinity, 52, DeelmarktRadius.lg, boneColor),
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            child: _bone(double.infinity, 52, DeelmarktRadius.lg, boneColor),
          ),
        ],
      ),
    );
  }
}

/// Skeleton bone shape — a rounded rectangle picked up by the shimmer.
Widget _bone(double width, double height, double radius, Color color) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: SizedBox(width: width, height: height),
  );
}
