import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Single review card with reviewer avatar, stars, and text.
///
/// Optional [onReport] enables DSA Art. 16 report action (three-dot menu).
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, this.onReport, super.key});

  final ReviewEntity review;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final name =
        review.isReviewerDeleted
            ? 'profile.deletedUser'.tr()
            : review.reviewerName;
    final avatarUrl =
        review.isReviewerDeleted ? null : review.reviewerAvatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeelAvatar(
            displayName: name,
            imageUrl: avatarUrl,
            size: DeelAvatarSize.small,
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    _buildStars(context),
                    if (onReport != null) _buildReportButton(context),
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

  Widget _buildReportButton(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        icon: Icon(PhosphorIcons.dotsThreeVertical(), size: 18),
        tooltip: 'review.report_review'.tr(),
        onPressed: onReport,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStars(BuildContext context) {
    return Semantics(
      label: 'review.a11y.rating_label'.tr(
        namedArgs: {'rating': '${review.rating.round()}'},
      ),
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
