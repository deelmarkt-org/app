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
                        // Image skeleton
                        const AspectRatio(
                          aspectRatio: 4 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: DeelmarktColors.neutral200,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Spacing.s4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trust banner
                              _bone(double.infinity, 56, DeelmarktRadius.sm),
                              const SizedBox(height: Spacing.s4),
                              // Title + price
                              Row(
                                children: [
                                  Expanded(
                                    child: _bone(
                                      double.infinity,
                                      24,
                                      DeelmarktRadius.sm,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.s4),
                                  _bone(80, 24, DeelmarktRadius.sm),
                                ],
                              ),
                              const SizedBox(height: Spacing.s3),
                              // Chips
                              Row(
                                children: [
                                  _bone(72, 24, DeelmarktRadius.full),
                                  const SizedBox(width: Spacing.s2),
                                  _bone(64, 24, DeelmarktRadius.full),
                                ],
                              ),
                              const SizedBox(height: Spacing.s4),
                              // Description lines
                              _bone(double.infinity, 14, DeelmarktRadius.xs),
                              const SizedBox(height: Spacing.s2),
                              _bone(double.infinity, 14, DeelmarktRadius.xs),
                              const SizedBox(height: Spacing.s2),
                              _bone(200, 14, DeelmarktRadius.xs),
                              const SizedBox(height: Spacing.s6),
                              // Seller card
                              Container(
                                padding: const EdgeInsets.all(Spacing.s4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    DeelmarktRadius.lg,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _bone(48, 48, DeelmarktRadius.full),
                                    const SizedBox(width: Spacing.s3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _bone(120, 16, DeelmarktRadius.xs),
                                          const SizedBox(height: Spacing.s2),
                                          _bone(80, 12, DeelmarktRadius.xs),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action bar skeleton
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.s4,
                    vertical: Spacing.s3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: const Border(
                      top: BorderSide(color: DeelmarktColors.neutral200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _bone(double.infinity, 52, DeelmarktRadius.lg),
                      ),
                      const SizedBox(width: Spacing.s3),
                      Expanded(
                        child: _bone(double.infinity, 52, DeelmarktRadius.lg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton bone shape — a rounded rectangle picked up by the shimmer.
  static Widget _bone(double width, double height, double radius) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeelmarktColors.neutral200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
