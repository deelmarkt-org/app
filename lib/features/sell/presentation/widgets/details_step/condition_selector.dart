import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

/// Condition selector using choice chips.
///
/// Shows the 4 seller-relevant conditions from the design spec:
/// Nieuw → newWithTags, Als nieuw → likeNew, Goed → good, Redelijk → fair.
class ConditionSelector extends StatelessWidget {
  const ConditionSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ListingCondition? selected;
  final void Function(ListingCondition) onChanged;

  static const _conditions = [
    ListingCondition.newWithTags,
    ListingCondition.likeNew,
    ListingCondition.good,
    ListingCondition.fair,
  ];

  String _labelFor(ListingCondition c) => switch (c) {
    ListingCondition.newWithTags => 'sell.conditionNew'.tr(),
    ListingCondition.likeNew => 'sell.conditionLikeNew'.tr(),
    ListingCondition.good => 'sell.conditionGood'.tr(),
    ListingCondition.fair => 'sell.conditionFair'.tr(),
    _ => c.name,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'sell.condition'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: Spacing.s2),
        Wrap(
          spacing: Spacing.s2,
          children:
              _conditions.map((c) {
                final isSelected = c == selected;
                return Semantics(
                  label: _labelFor(c),
                  child: ChoiceChip(
                    label: Text(_labelFor(c)),
                    selected: isSelected,
                    selectedColor: DeelmarktColors.primarySurface,
                    onSelected: (_) => onChanged(c),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
