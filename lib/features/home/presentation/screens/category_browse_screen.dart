import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_browse_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_card.dart';

/// Browse all L1 categories screen.
///
/// Compact (<840): vertical list of full-width [CategoryCard]s.
/// Expanded (≥840): 2-column grid per
/// `docs/screens/02-home/designs/category_browse_desktop_light`. Content
/// is capped at 1000 px because the cards are dense (80 px, icon + label +
/// chevron) and a wider container would stretch them disproportionately.
///
/// Route: `/categories` (AppRoutes.categories)
///
/// Reference: docs/screens/02-home/04-category-browse.md
class CategoryBrowseScreen extends ConsumerWidget {
  const CategoryBrowseScreen({super.key});

  /// Max content width on expanded viewports — narrower than the default
  /// `Breakpoints.large` (1200) because 2-col of 80-px cards reads best
  /// when each card is ~480 px wide. Reference: issue #193 PR B §Scope.
  static const double _maxWidth = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryBrowseNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('category.title'.tr())),
      body: state.when(
        loading: () => const _LoadingView(),
        error:
            (_, _) => ErrorState(
              onRetry:
                  () =>
                      ref
                          .read(categoryBrowseNotifierProvider.notifier)
                          .refresh(),
            ),
        data:
            (categories) => _DataView(
              categories: categories,
              onRefresh:
                  () =>
                      ref
                          .read(categoryBrowseNotifierProvider.notifier)
                          .refresh(),
            ),
      ),
    );
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.categories, required this.onRefresh});

  final List<CategoryEntity> categories;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody.wide(
      maxWidth: CategoryBrowseScreen._maxWidth,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxWidth >= Breakpoints.medium;
            return isExpanded
                ? _buildGrid(context, constraints)
                : _buildList(context);
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.s4),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.s3),
      itemBuilder: (context, index) => _card(context, categories[index]),
    );
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    // CategoryCard is fixed-height (80). Compute cross-axis extent from the
    // available width so the aspect ratio stays correct across the whole
    // 840-to-1000 expanded range; the card's internal layout is responsible
    // for looking good at 400–490 px.
    const outerPadding = Spacing.s4 * 2; // left + right
    const gap = Spacing.s3;
    final itemWidth = (constraints.maxWidth - outerPadding - gap) / 2;
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      padding: const EdgeInsets.all(Spacing.s4),
      childAspectRatio: itemWidth / 80,
      children: [for (final category in categories) _card(context, category)],
    );
  }

  Widget _card(BuildContext context, CategoryEntity category) {
    return CategoryCard(
      category: category,
      onTap:
          () => context.push(
            AppRoutes.categoryDetail.replaceAll(':id', category.id),
          ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const _skeletonCount = 8;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody.wide(
      maxWidth: CategoryBrowseScreen._maxWidth,
      child: SkeletonLoader(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxWidth >= Breakpoints.medium;
            return isExpanded
                ? _buildGridSkeleton(constraints)
                : _buildListSkeleton();
          },
        ),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Column(
        children: List.generate(
          _skeletonCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < _skeletonCount - 1 ? Spacing.s3 : 0,
            ),
            child: const SkeletonBox(height: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSkeleton(BoxConstraints constraints) {
    const outerPadding = Spacing.s4 * 2;
    const gap = Spacing.s3;
    final itemWidth = (constraints.maxWidth - outerPadding - gap) / 2;
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      padding: const EdgeInsets.all(Spacing.s4),
      childAspectRatio: itemWidth / 80,
      children: List.generate(
        _skeletonCount,
        (_) => const SkeletonBox(height: 80),
      ),
    );
  }
}
