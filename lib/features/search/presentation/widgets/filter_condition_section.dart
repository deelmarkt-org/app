import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Condition checkbox section for the filter bottom sheet.
class FilterConditionSection extends StatelessWidget {
  const FilterConditionSection({
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
          'search.filter.condition'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        ...ListingCondition.values.map((c) {
          return CheckboxListTile(
            title: Text('condition.${c.name}'.tr()),
            value: filter.condition == c,
            onChanged: (checked) {
              onChanged(
                filter.copyWith(condition: () => checked == true ? c : null),
              );
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ],
    );
  }
}
