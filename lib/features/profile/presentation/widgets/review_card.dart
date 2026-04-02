import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Single review card with reviewer avatar, stars, and text.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final ReviewEntity review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeelAvatar(
            displayName: review.reviewerName,
            imageUrl: review.reviewerAvatarUrl,
            size: DeelAvatarSize.small,
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.reviewerName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    _buildStars(context),
                  ],
                ),
                const SizedBox(height: Spacing.s1),
                Text(review.text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(BuildContext context) {
    return Semantics(
      label: '${review.rating} out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isFilled = index < review.rating.round();
          return Icon(
            isFilled
                ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                : PhosphorIcons.star(),
            size: 14,
            color:
                isFilled ? DeelmarktColors.warning : DeelmarktColors.neutral300,
          );
        }),
      ),
    );
  }
}
