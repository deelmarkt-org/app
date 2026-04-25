import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Horizontal scrollable row of filter chips used on compact viewports
/// (<840). Tapping any chip opens the filter bottom sheet via [onTap].
///
/// The desktop variant uses the shared [FilterPanel] sidebar instead —
/// see `search_results_view.dart` §Responsive.
class SearchFilterChipBar extends StatelessWidget {
  const SearchFilterChipBar({
    required this.filter,
    required this.onTap,
    required this.isDark,
    super.key,
  });

  final SearchFilter filter;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            context,
            label: 'search.filter.price'.tr(),
            isActive:
                filter.minPriceCents != null || filter.maxPriceCents != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.condition'.tr(),
            isActive: filter.condition != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.distance'.tr(),
            isActive: filter.maxDistanceKm != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.category'.tr(),
            isActive: filter.categoryId != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.sort'.tr(),
            isActive: filter.sortOrder != SearchSortOrder.relevance,
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeColor =
        isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary;
    final activeBg =
        isDark
            ? DeelmarktColors.darkPrimary.withValues(alpha: 0.12)
            : DeelmarktColors.primarySurface;

    return Semantics(
      button: true,
      label: label,
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
          side: BorderSide(
            color: isActive ? activeColor : theme.colorScheme.outlineVariant,
          ),
        ),
        backgroundColor: isActive ? activeBg : null,
      ),
    );
  }
}
