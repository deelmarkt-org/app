import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_browse_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_card.dart';

/// Browse all L1 categories screen.
///
/// Route: `/categories` (AppRoutes.categories)
class CategoryBrowseScreen extends ConsumerWidget {
  const CategoryBrowseScreen({super.key});

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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacing.s4),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.s3),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            onTap: () => context.push('/categories/${category.id}'),
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const _skeletonCount = 8;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
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
      ),
    );
  }
}
