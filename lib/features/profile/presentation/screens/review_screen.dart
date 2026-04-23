import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/profile/presentation/notifiers/review_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_draft_form.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_result_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Post-transaction review screen (P-38).
///
/// Fullscreen dialog with blind review flow:
/// loading → ineligible | draft → submitting → submitted → bothVisible | error
///
/// Reference: docs/epics/E06-trust-moderation.md §Ratings & Reviews
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(reviewNotifierProvider(transactionId));

    return PopScope(
      canPop: !_hasUnsavedChanges(ref),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDiscardDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('review.title'.tr())),
        body: SafeArea(
          // maxWidth 500 matches docs/screens/07-profile/04-rating-review.md
          // §Expanded; keeps the form readable and not stretched across desktop
          // viewports.
          child: ResponsiveBody(
            maxWidth: 500,
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => ErrorState(
                    message: error.toString(),
                    onRetry:
                        () => ref.invalidate(
                          reviewNotifierProvider(transactionId),
                        ),
                  ),
              data: (state) => _buildState(context, ref, state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildState(
    BuildContext context,
    WidgetRef ref,
    ReviewScreenState screenState,
  ) {
    final notifier = ref.read(reviewNotifierProvider(transactionId).notifier);

    return switch (screenState) {
      ReviewLoading() ||
      ReviewSubmitting() => const Center(child: CircularProgressIndicator()),
      ReviewIneligible(:final reason) => ReviewIneligibleView(reason: reason),
      ReviewDraftState() => ReviewDraftForm(
        draft: screenState,
        onRatingChanged: notifier.updateRating,
        onBodyChanged: notifier.updateBody,
        onSubmit: notifier.submit,
      ),
      ReviewSubmitted(:final role) => ReviewSubmittedView(role: role),
      ReviewBothVisible(:final myReview, :final theirReview) =>
        ReviewBothVisibleView(myReview: myReview, theirReview: theirReview),
      ReviewError(:final errorClass, :final retryAfterSeconds) =>
        ReviewErrorView(
          errorClass: errorClass,
          retryAfterSeconds: retryAfterSeconds,
          onRetry:
              errorClass != ReviewErrorClass.conflict &&
                      errorClass != ReviewErrorClass.expired
                  ? notifier.retry
                  : null,
        ),
    };
  }

  bool _hasUnsavedChanges(WidgetRef ref) {
    final notifier = ref.read(reviewNotifierProvider(transactionId).notifier);
    return notifier.hasUnsavedChanges();
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('review.unsaved_discard'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('review.unsaved_keep'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text('review.close'.tr()),
              ),
            ],
          ),
    );
  }
}
