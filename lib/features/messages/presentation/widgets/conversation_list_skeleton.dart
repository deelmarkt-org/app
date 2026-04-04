import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

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
    final colors = ChatThemeColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final rows = Column(
      children: List.generate(itemCount, (_) => _SkeletonRow(colors: colors)),
    );

    if (reduceMotion) return rows;

    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: rows,
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.colors});

  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final placeholder = colors.shimmerPlaceholder;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s2,
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s5),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(color: colors.border),
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
