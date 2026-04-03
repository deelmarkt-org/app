import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

/// List of user reviews.
class ReviewsTabView extends StatelessWidget {
  const ReviewsTabView({
    required this.reviews,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<ReviewEntity>> reviews;
  final VoidCallback onRetry;

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
              'profile.noReviews'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: items.map((r) => ReviewCard(review: r)).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: placeholderColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: placeholderColor),
                const SizedBox(height: 4),
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
