import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

import 'package:deelmarkt/features/home/presentation/widgets/category_icon_mapper.dart';

/// L2 subcategory chip — rounded pill with icon and label.
///
/// Min height 44px for WCAG 2.2 touch target compliance.
///
/// Reference: docs/design-system/patterns.md - Category Browse
class SubcategoryChip extends StatelessWidget {
  const SubcategoryChip({
    required this.category,
    required this.onTap,
    super.key,
  });

  final CategoryEntity category;
  final VoidCallback onTap;

  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = categoryIconFor(category.icon);

    return Semantics(
      label: category.name,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.full),
          child: Container(
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.s4,
              vertical: Spacing.s2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DeelmarktRadius.full),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surfaceContainerLow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: DeelmarktIconSize.sm,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.s2),
                Text(category.name, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
