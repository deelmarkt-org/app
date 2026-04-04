import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

import 'package:deelmarkt/features/home/presentation/widgets/category_icon_mapper.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_tint_colors.dart';

/// L1 category card — 80px row with tinted icon, name, and chevron.
///
/// Reference: docs/design-system/patterns.md - Category Browse
class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, required this.onTap, super.key});

  final CategoryEntity category;
  final VoidCallback onTap;

  static const double _cardHeight = 80;
  static const double _iconContainerSize = 48;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = categoryTintFor(category.id, brightness);
    final icon = categoryIconFor(category.icon);

    return Semantics(
      label: category.name,
      button: true,
      child: Material(
        color: tint.background,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          child: SizedBox(
            height: _cardHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s4,
                vertical: Spacing.s4,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: _iconContainerSize / 2,
                    backgroundColor: tint.iconBackground,
                    child: Icon(
                      icon,
                      color: tint.iconForeground,
                      size: DeelmarktIconSize.md,
                    ),
                  ),
                  const SizedBox(width: Spacing.s4),
                  Expanded(
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: DeelmarktIconSize.sm,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
