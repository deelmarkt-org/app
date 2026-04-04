import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// P-35 — Shimmer skeleton used while conversations load.
///
/// Reference: `docs/screens/06-chat/designs/messages_loading_state`.
/// Renders 5 placeholder rows whose geometry roughly matches
/// [ConversationListTile]. Shimmer is disabled when the user has
/// requested reduced motion via `MediaQuery.disableAnimations`.
class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final baseColor =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral100;
    final highlightColor =
        isDark
            ? DeelmarktColors.darkShimmerHighlight
            : DeelmarktColors.neutral50;

    final rows = Column(
      children: List.generate(itemCount, (_) => _SkeletonRow(isDark: isDark)),
    );

    if (reduceMotion) {
      return rows;
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: rows,
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral200;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s2,
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s5),
        decoration: BoxDecoration(
          color: isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(
            color:
                isDark
                    ? DeelmarktColors.darkBorder
                    : DeelmarktColors.neutral200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: placeholder,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(placeholder, width: 140, height: 14),
                  const SizedBox(height: Spacing.s2),
                  _bar(placeholder, width: double.infinity, height: 12),
                  const SizedBox(height: Spacing.s2),
                  _bar(placeholder, width: 72, height: 10),
                ],
              ),
            ),
            const SizedBox(width: Spacing.s3),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
      ),
    );
  }
}
