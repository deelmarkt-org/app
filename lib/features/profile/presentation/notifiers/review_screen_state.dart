import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// Error classification for review submission failures.
enum ReviewErrorClass {
  network,
  conflict,
  expired,
  cancelled,
  rateLimit,
  moderationBlocked,
  unknown,
}

/// State for the review screen — sealed hierarchy covering all states.
sealed class ReviewScreenState {
  const ReviewScreenState();
}

class ReviewLoading extends ReviewScreenState {
  const ReviewLoading();
}

class ReviewIneligible extends ReviewScreenState {
  const ReviewIneligible({required this.reason});
  final String reason;
}

class ReviewDraftState extends ReviewScreenState {
  const ReviewDraftState({
    required this.rating,
    required this.body,
    required this.idempotencyKey,
    required this.revieweeName,
    required this.role,
    this.hasRestoredDraft = false,
  });

  final double rating;
  final String body;
  final String idempotencyKey;
  final String revieweeName;
  final ReviewRole role;
  final bool hasRestoredDraft;

  bool get canSubmit => rating >= 1 && body.trim().length <= 500;

  ReviewDraftState copyWith({double? rating, String? body}) => ReviewDraftState(
    rating: rating ?? this.rating,
    body: body ?? this.body,
    idempotencyKey: idempotencyKey,
    revieweeName: revieweeName,
    role: role,
    hasRestoredDraft: hasRestoredDraft,
  );
}

class ReviewSubmitting extends ReviewScreenState {
  const ReviewSubmitting();
}

class ReviewSubmitted extends ReviewScreenState {
  const ReviewSubmitted({required this.role});
  final ReviewRole role;
}

class ReviewBothVisible extends ReviewScreenState {
  const ReviewBothVisible({required this.myReview, required this.theirReview});
  final ReviewEntity myReview;
  final ReviewEntity theirReview;
}

class ReviewError extends ReviewScreenState {
  const ReviewError({required this.errorClass, this.retryAfterSeconds});
  final ReviewErrorClass errorClass;
  final int? retryAfterSeconds;
}
