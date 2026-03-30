import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

/// Horizontal carousel of L1 category pills on the home screen.
class CategoryCarousel extends StatelessWidget {
  const CategoryCarousel({
    required this.categories,
    required this.onCategoryTap,
    super.key,
  });

  final List<CategoryEntity> categories;
  final ValueChanged<CategoryEntity> onCategoryTap;

  static const double _iconContainerSize = 48;

  /// Map category icon name to Phosphor icon.
  static IconData _iconFor(String name) => switch (name) {
    'car' => PhosphorIcons.car(),
    'device-mobile' => PhosphorIcons.deviceMobile(),
    'house' => PhosphorIcons.house(),
    't-shirt' => PhosphorIcons.tShirt(),
    'bicycle' => PhosphorIcons.bicycle(),
    'baby' => PhosphorIcons.baby(),
    'wrench' => PhosphorIcons.wrench(),
    'dots-three' => PhosphorIcons.dotsThree(),
    _ => PhosphorIcons.tag(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: Text(
            'home.categories'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: Spacing.s3),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.s3),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryPill(
                category: cat,
                icon: _iconFor(cat.icon),
                onTap: () => onCategoryTap(cat),
                iconContainerSize: _iconContainerSize,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.icon,
    required this.onTap,
    required this.iconContainerSize,
  });

  final CategoryEntity category;
  final IconData icon;
  final VoidCallback onTap;
  final double iconContainerSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: category.name,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
                ),
                child: Icon(icon, color: DeelmarktColors.primary, size: 24),
              ),
              const SizedBox(height: Spacing.s2),
              Text(
                category.name,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
