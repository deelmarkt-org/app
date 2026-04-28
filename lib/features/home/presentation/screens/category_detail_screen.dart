import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_detail_data_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_detail_loading.dart';
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
            (data) => CategoryDetailDataView(
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
