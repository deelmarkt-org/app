import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_detail_loading.dart';
import 'package:deelmarkt/features/home/presentation/widgets/featured_listings_grid.dart';
import 'package:deelmarkt/features/home/presentation/widgets/subcategory_chip.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Category detail screen — hero, subcategory chips, and featured listings.
///
/// Route: `/categories/:id` (AppRoutes.categoryDetail)
///
/// Reference: docs/screens/02-home/04-category-browse.md (sub-screen of
/// the category browse flow — same spec governs L2 list rendering).
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryDetailNotifierProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: state.whenOrNull(
          data:
              (data) => Text(
                data.parent.name,
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? DeelmarktColors.darkPrimary
                          : DeelmarktColors.primary,
                ),
              ),
        ),
      ),
      body: state.when(
        loading: () => const CategoryDetailLoading(),
        error:
            (_, _) => ErrorState(
              onRetry:
                  () => ref.invalidate(
                    categoryDetailNotifierProvider(categoryId),
                  ),
            ),
        data:
            (data) => _DataView(
              state: data,
              onToggleFavourite:
                  (id) => ref
                      .read(categoryDetailNotifierProvider(categoryId).notifier)
                      .toggleFavourite(id),
            ),
      ),
    );
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.state, required this.onToggleFavourite});

  final CategoryDetailState state;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s4,
              Spacing.s4,
              Spacing.s4,
              Spacing.s6,
            ),
            child: Text(
              'category.heroTitle'.tr(args: [state.parent.name]),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        // Subcategory chips
        if (state.subcategories.isNotEmpty)
          SliverToBoxAdapter(
            child: _SubcategoryChips(subcategories: state.subcategories),
          ),
        // Featured listings header + grid
        if (state.featuredListings.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s4,
                0,
                Spacing.s4,
                Spacing.s3,
              ),
              child: Text(
                'category.recommendedIn'.tr(args: [state.parent.name]),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          FeaturedListingsGrid(
            listings: state.featuredListings,
            onToggleFavourite: onToggleFavourite,
          ),
        ],
        // Empty state
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
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({required this.subcategories});
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
