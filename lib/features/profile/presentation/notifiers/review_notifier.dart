import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_helpers.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/providers/review_draft_provider.dart';

part 'review_notifier.g.dart';

/// Review screen state machine. Reference: E06 §Ratings & Reviews
@riverpod
class ReviewNotifier extends _$ReviewNotifier {
  String _idempotencyKey = '';
  String _revieweeName = '';
  ReviewRole _role = ReviewRole.buyer;
  ReviewDraftNotifier get _drafts =>
      ref.read(reviewDraftNotifierProvider(transactionId).notifier);

  @override
  Future<ReviewScreenState> build(String transactionId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      return const ReviewIneligible(reason: 'review.error.ineligible.auth');
    }
    final txn = await ref
        .read(transactionRepositoryProvider)
        .getTransaction(transactionId);
    if (txn == null) {
      return const ReviewIneligible(reason: 'review.error.ineligible.notFound');
    }
    final ineligible = checkReviewEligibility(txn.status);
    if (ineligible != null) return ReviewIneligible(reason: ineligible);
    _role =
        currentUser.id == txn.buyerId ? ReviewRole.buyer : ReviewRole.seller;
    _revieweeName = _role == ReviewRole.buyer ? 'Verkoper' : 'Koper';
    final reviews = await ref
        .read(reviewRepositoryProvider)
        .getForTransaction(transactionId);
    final my = reviews.where((r) => r.reviewerId == currentUser.id).firstOrNull;
    final their =
        reviews.where((r) => r.reviewerId != currentUser.id).firstOrNull;
    if (my != null && their != null) {
      return ReviewBothVisible(myReview: my, theirReview: their);
    }
    if (my != null) return ReviewSubmitted(role: _role);
    final existing = ref.read(reviewDraftNotifierProvider(transactionId));
    if (existing != null) {
      _idempotencyKey = existing.idempotencyKey;
      return ReviewDraftState(
        rating: existing.rating,
        body: existing.body,
        idempotencyKey: existing.idempotencyKey,
        revieweeName: _revieweeName,
        role: _role,
        hasRestoredDraft: true,
      );
    }
    _idempotencyKey = generateIdempotencyKey();
    _drafts.save(
      ReviewDraft(
        rating: 0,
        body: '',
        idempotencyKey: _idempotencyKey,
        lastModifiedAt: DateTime.now(),
      ),
    );
    return ReviewDraftState(
      rating: 0,
      body: '',
      idempotencyKey: _idempotencyKey,
      revieweeName: _revieweeName,
      role: _role,
    );
  }

  void updateRating(double value) {
    final c = state.valueOrNull;
    if (c is! ReviewDraftState) return;
    HapticFeedback.selectionClick();
    final u = c.copyWith(rating: value);
    state = AsyncValue.data(u);
    _persistDraft(u);
  }

  void updateBody(String body) {
    final c = state.valueOrNull;
    if (c is! ReviewDraftState) return;
    final u = c.copyWith(body: body);
    state = AsyncValue.data(u);
    _persistDraft(u);
  }

  Future<void> submit() async {
    final c = state.valueOrNull;
    if (c is! ReviewDraftState || !c.canSubmit) return;
    state = const AsyncValue.data(ReviewSubmitting());
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submitReview(
            ReviewSubmission(
              transactionId: transactionId,
              rating: c.rating,
              body: sanitizeReviewBody(c.body),
              role: c.role,
              idempotencyKey: c.idempotencyKey,
            ),
          );
      _drafts.clear();
      state = AsyncValue.data(ReviewSubmitted(role: c.role));
    } on Exception catch (e) {
      state = AsyncValue.data(ReviewError(errorClass: classifyReviewError(e)));
    }
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(transactionId));
  }

  bool hasUnsavedChanges() {
    final c = state.valueOrNull;
    if (c is! ReviewDraftState) return false;
    return c.body.trim().isNotEmpty || c.rating > 0;
  }

  void _persistDraft(ReviewDraftState d) {
    _drafts.save(
      ReviewDraft(
        rating: d.rating,
        body: d.body,
        idempotencyKey: d.idempotencyKey,
        lastModifiedAt: DateTime.now(),
      ),
    );
  }
}
