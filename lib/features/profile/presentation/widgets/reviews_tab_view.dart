import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// List of user reviews with optional pagination.
class ReviewsTabView extends StatelessWidget {
  const ReviewsTabView({
    required this.reviews,
    required this.onRetry,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onReport,
    super.key,
  });

  final AsyncValue<List<ReviewEntity>> reviews;
  final VoidCallback onRetry;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final void Function(ReviewEntity review)? onReport;

  @override
  Widget build(BuildContext context) {
    return reviews.when(
      loading:
          () => SkeletonLoader(
            child: Column(
              children: List.generate(3, (_) => const _ReviewSkeleton()),
            ),
          ),
      error:
          (_, _) => ErrorState(message: 'error.generic'.tr(), onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'profile.no_reviews'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            ...items.map(
              (r) => ReviewCard(
                review: r,
                onReport: onReport != null ? () => onReport!(r) : null,
              ),
            ),
            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(Spacing.s4),
                child: CircularProgressIndicator(),
              ),
            if (hasMore && !isLoadingMore && onLoadMore != null)
              Semantics(
                button: true,
                label: 'seller_profile.load_more'.tr(),
                child: TextButton(
                  onPressed: onLoadMore,
                  child: Text('seller_profile.load_more'.tr()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerLow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Row(
        children: [
          Container(
            width: Spacing.s8,
            height: Spacing.s8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: placeholderColor,
            ),
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: placeholderColor),
                const SizedBox(height: Spacing.s1),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: placeholderColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
