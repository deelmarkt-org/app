import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_providers.dart';

/// Category filter section shared by [FilterPanel] (sheet and sidebar variants).
///
/// Renders a [Wrap] of [FilterChip] widgets — one per L1 category.
/// The selected chip reflects [filter.categoryId]; tapping a chip that is
/// already selected deselects it (sets categoryId to null).
///
/// Reference: docs/screens/02-home/03-search.md §Filter Panel.
class FilterCategorySection extends ConsumerWidget {
  const FilterCategorySection({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(topLevelCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.category'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        categoriesAsync.when(
          loading: () => const SizedBox(height: Spacing.s12),
          error:
              (_, _) => TextButton.icon(
                onPressed: () => ref.invalidate(topLevelCategoriesProvider),
                icon: const Icon(Icons.refresh, size: DeelmarktIconSize.xs),
                label: Text('action.retry'.tr()),
              ),
          data:
              (categories) => Wrap(
                spacing: Spacing.s2,
                runSpacing: Spacing.s2,
                children:
                    categories.map((cat) {
                      final isSelected = filter.categoryId == cat.id;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          onChanged(
                            filter.copyWith(
                              categoryId: () => selected ? cat.id : null,
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DeelmarktRadius.xxl,
                          ),
                        ),
                      );
                    }).toList(),
              ),
        ),
      ],
    );
  }
}
