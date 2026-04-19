import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

/// Distance slider section for the filter bottom sheet.
class FilterDistanceSection extends StatelessWidget {
  const FilterDistanceSection({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  static const _maxDistanceKm = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = filter.maxDistanceKm ?? _maxDistanceKm;
    final distanceLabel = '${distance.round()} km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.distance'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        Semantics(
          label: 'search.filter.distance'.tr(),
          value: distanceLabel,
          child: Slider(
            value: distance,
            min: 1,
            max: _maxDistanceKm,
            divisions: 99,
            label: distanceLabel,
            onChanged: (value) {
              onChanged(
                filter.copyWith(
                  maxDistanceKm: () => value >= _maxDistanceKm ? null : value,
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: theme.textTheme.bodySmall),
            Text(
              distance >= _maxDistanceKm
                  ? 'search.filter.anyDistance'.tr()
                  : distanceLabel,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
