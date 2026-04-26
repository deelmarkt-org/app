import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_detail_data_view_parts.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_featured_listing_card.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_subcategory_chips.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Data-state view for the category detail screen.
///
/// Composes hero, subcategory chips, the featured listings grid, and an
/// empty-state filler when both subcategories and featured listings are
/// empty. Wrapped in [ResponsiveBody.wide] so the grid caps at the desktop
/// breakpoint instead of stretching edge-to-edge.
class CategoryDetailDataView extends StatelessWidget {
  const CategoryDetailDataView({
    required this.state,
    required this.onToggleFavourite,
    super.key,
  });

  final CategoryDetailState state;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    // ResponsiveBody.wide caps the grid at Breakpoints.large (1200) on
    // ultra-wide viewports. Each sliver owns its own horizontal padding
    // (Spacing.s4), so the wrapper's padding is intentionally off (§193 PR A).
    return ResponsiveBody.wide(
      child: CustomScrollView(
        slivers: [
          CategoryDetailHero(parentName: state.parent.name),
          if (state.subcategories.isNotEmpty)
            SliverToBoxAdapter(
              child: CategorySubcategoryChips(
                subcategories: state.subcategories,
              ),
            ),
          if (state.featuredListings.isNotEmpty) ...[
            CategoryDetailFeaturedHeader(parentName: state.parent.name),
            AdaptiveListingGrid(
              itemCount: state.featuredListings.length,
              itemBuilder:
                  (context, index) => CategoryFeaturedListingCard(
                    listing: state.featuredListings[index],
                    onToggleFavourite: onToggleFavourite,
                  ),
            ),
          ],
          if (state.featuredListings.isEmpty && state.subcategories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'category.empty'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.s8)),
        ],
      ),
    );
  }
}
