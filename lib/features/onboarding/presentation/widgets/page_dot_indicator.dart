import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';

/// Animated page indicator dots for the onboarding PageView.
///
/// Active dot: 10dp, primary colour. Inactive: 8dp, outline variant.
/// Respects [MediaQuery.disableAnimations] for reduced motion.
/// WCAG: Includes [Semantics] label "Page X of Y".
class PageDotIndicator extends StatelessWidget {
  const PageDotIndicator({
    required this.currentPage,
    required this.pageCount,
    super.key,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return Semantics(
      label: 'onboarding.page_indicator'.tr(
        namedArgs: {'current': '${currentPage + 1}', 'total': '$pageCount'},
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : Spacing.s2),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
              ),
            ),
          );
        }),
      ),
    );
  }
}
