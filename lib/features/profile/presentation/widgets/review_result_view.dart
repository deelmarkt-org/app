import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Ineligible state view — shows warning icon and reason.
class ReviewIneligibleView extends StatelessWidget {
  const ReviewIneligibleView({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48,
              color: DeelmarktColors.warning,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              reason.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Submitted waiting state — shows success icon and waiting message.
class ReviewSubmittedView extends StatelessWidget {
  const ReviewSubmittedView({required this.role, super.key});

  final ReviewRole role;

  @override
  Widget build(BuildContext context) {
    final roleLabel =
        (role == ReviewRole.buyer ? 'review.role.seller' : 'review.role.buyer')
            .tr();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              size: 64,
              color: DeelmarktColors.success,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'review.thankYou'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.s2),
            Text(
              'review.waitingForOther'.tr(namedArgs: {'role': roleLabel}),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s6),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('review.close'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Both visible state — shows both review cards.
class ReviewBothVisibleView extends StatelessWidget {
  const ReviewBothVisibleView({
    required this.myReview,
    required this.theirReview,
    super.key,
  });

  final ReviewEntity myReview;
  final ReviewEntity theirReview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'review.bothVisible'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.s4),
            ReviewCard(review: myReview),
            const SizedBox(height: Spacing.s3),
            ReviewCard(review: theirReview),
          ],
        ),
      ),
    );
  }
}

/// Error state view — retryable or non-retryable.
class ReviewErrorView extends StatelessWidget {
  const ReviewErrorView({
    required this.errorClass,
    this.retryAfterSeconds,
    this.onRetry,
    super.key,
  });

  final ReviewErrorClass errorClass;
  final int? retryAfterSeconds;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final errorKey = switch (errorClass) {
      ReviewErrorClass.network => 'review.error.network',
      ReviewErrorClass.conflict => 'review.error.conflict',
      ReviewErrorClass.expired => 'review.error.expired',
      ReviewErrorClass.cancelled => 'review.error.cancelled',
      ReviewErrorClass.rateLimit => 'review.error.rateLimit',
      ReviewErrorClass.moderationBlocked => 'review.error.moderationBlocked',
      ReviewErrorClass.unknown => 'review.error.unknown',
    };

    final message = errorKey.tr(
      namedArgs: {'seconds': '${retryAfterSeconds ?? 60}'},
    );

    if (onRetry != null) {
      return ErrorState(message: message, onRetry: onRetry!);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              size: 48,
              color: DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s6),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('review.close'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
