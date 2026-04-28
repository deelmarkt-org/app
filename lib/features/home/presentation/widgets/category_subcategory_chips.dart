import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/subcategory_chip.dart';

/// "Refine your search" subcategory chip row shown above the featured-
/// listings grid on the category detail screen.
///
/// Tapping a chip pushes the search route filtered by the chip's category.
class CategorySubcategoryChips extends StatelessWidget {
  const CategorySubcategoryChips({required this.subcategories, super.key});

  final List<CategoryEntity> subcategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'category.refineSearch'.tr(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: Spacing.s3),
          Wrap(
            spacing: Spacing.s2,
            runSpacing: Spacing.s2,
            children: [
              for (final subcat in subcategories)
                SubcategoryChip(
                  category: subcat,
                  onTap:
                      () => context.push(
                        '${AppRoutes.search}?category=${subcat.id}',
                      ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.s6),
        ],
      ),
    );
  }
}
