import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Sort-order filter section shared by [FilterPanel] (sheet and sidebar variants).
///
/// Renders a [RadioListTile] group for each [SearchSortOrder] value.
///
/// Reference: docs/screens/02-home/03-search.md §Filter Panel.
class FilterSortSection extends StatelessWidget {
  const FilterSortSection({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.sort'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        RadioGroup<SearchSortOrder>(
          groupValue: filter.sortOrder,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(sortOrder: value));
            }
          },
          child: Column(
            children:
                SearchSortOrder.values.map((s) {
                  return RadioListTile<SearchSortOrder>(
                    title: Text('search.sort.${s.name}'.tr()),
                    value: s,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
