import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Price range slider section for the filter bottom sheet.
class FilterPriceSection extends StatelessWidget {
  const FilterPriceSection({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  static const _maxPriceCents = 500000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = (filter.minPriceCents ?? 0).toDouble();
    final max = (filter.maxPriceCents ?? _maxPriceCents).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.price'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        Semantics(
          label: 'search.filter.price'.tr(),
          child: RangeSlider(
            values: RangeValues(min, max),
            max: _maxPriceCents.toDouble(),
            divisions: 100,
            labels: RangeLabels(
              Formatters.euroFromCents(min.round()),
              Formatters.euroFromCents(max.round()),
            ),
            onChanged: (values) {
              onChanged(
                filter.copyWith(
                  minPriceCents:
                      () => values.start > 0 ? values.start.round() : null,
                  maxPriceCents:
                      () =>
                          values.end < _maxPriceCents
                              ? values.end.round()
                              : null,
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.euroFromCents(min.round()),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              Formatters.euroFromCents(max.round()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
