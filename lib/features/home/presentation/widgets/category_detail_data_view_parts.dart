import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';

/// Hero text sliver for the category detail data view — "Categorienaam,
/// hier zijn onze beste vondsten" (or the EN equivalent), padded so the
/// type matches the design's vertical rhythm.
class CategoryDetailHero extends StatelessWidget {
  const CategoryDetailHero({required this.parentName, super.key});

  final String parentName;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s4,
          Spacing.s4,
          Spacing.s4,
          Spacing.s6,
        ),
        child: Text(
          'category.heroTitle'.tr(args: [parentName]),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

/// "Recommended in {category}" header above the featured listings grid.
class CategoryDetailFeaturedHeader extends StatelessWidget {
  const CategoryDetailFeaturedHeader({required this.parentName, super.key});

  final String parentName;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s4,
          0,
          Spacing.s4,
          Spacing.s3,
        ),
        child: Text(
          'category.recommendedIn'.tr(args: [parentName]),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
