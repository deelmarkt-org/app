import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/subcategory_chip.dart';

/// Category detail screen — hero, subcategory chips, and featured listings.
///
/// Route: `/categories/:id` (AppRoutes.categoryDetail)
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
        loading: () => const _LoadingView(),
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
        if (state.subcategories.isNotEmpty)
          SliverToBoxAdapter(
            child: _SubcategoryChipsSection(subcategories: state.subcategories),
          ),
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
          _FeaturedListingsGrid(
            listings: state.featuredListings,
            onToggleFavourite: onToggleFavourite,
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
    );
  }
}

class _SubcategoryChipsSection extends StatelessWidget {
  const _SubcategoryChipsSection({required this.subcategories});
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

class _FeaturedListingsGrid extends StatelessWidget {
  const _FeaturedListingsGrid({
    required this.listings,
    required this.onToggleFavourite,
  });

  final List<ListingEntity> listings;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Spacing.listingCardGap,
          crossAxisSpacing: Spacing.listingCardGap,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final listing = listings[index];
          return DeelCard.grid(
            imageUrl:
                listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
            priceFormatted: Formatters.euroFromCents(listing.priceInCents),
            title: listing.title,
            location: listing.location,
            isFavourited: listing.isFavourited,
            onFavouriteTap: () => onToggleFavourite(listing.id),
            onTap:
                () => context.push(
                  AppRoutes.listingDetail.replaceAll(':id', listing.id),
                ),
          );
        }, childCount: listings.length),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 28, width: 200),
            const SizedBox(height: Spacing.s6),
            const SkeletonBox(height: 16, width: 120),
            const SizedBox(height: Spacing.s3),
            Wrap(
              spacing: Spacing.s2,
              runSpacing: Spacing.s2,
              children: List.generate(
                5,
                (_) => const SkeletonBox(height: 44, width: 100),
              ),
            ),
            const SizedBox(height: Spacing.s6),
            const SkeletonBox(height: 16, width: 160),
            const SizedBox(height: Spacing.s3),
            const Expanded(child: SkeletonBox(height: double.infinity)),
          ],
        ),
      ),
    );
  }
}
