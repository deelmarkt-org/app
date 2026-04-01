import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

/// Condition pill chip (e.g. "Als nieuw").
class ConditionChip extends StatelessWidget {
  const ConditionChip({required this.condition, super.key});

  final ListingCondition condition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = 'condition.${condition.name}'.tr();
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s2,
          vertical: Spacing.s1,
        ),
        decoration: BoxDecoration(
          color:
              isDark
                  ? DeelmarktColors.darkSurfaceElevated
                  : DeelmarktColors.neutral100,
          borderRadius: BorderRadius.circular(DeelmarktRadius.full),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isDark
                    ? DeelmarktColors.darkOnSurface
                    : DeelmarktColors.neutral700,
          ),
        ),
      ),
    );
  }
}

/// Category pill chip (e.g. "Meubels").
class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? DeelmarktColors.darkInfoSurface
                : DeelmarktColors.secondarySurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color:
              isDark
                  ? DeelmarktColors.darkSecondary
                  : DeelmarktColors.secondary,
        ),
      ),
    );
  }
}
