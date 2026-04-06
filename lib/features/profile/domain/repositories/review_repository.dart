import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';

/// Review repository interface — domain layer.
///
/// Implementations: MockReviewRepository (dev), SupabaseReviewRepository (prod).
/// Swapped via Riverpod provider overrides — no conditional logic (ADR-MOCK-SWAP).
abstract class ReviewRepository {
  /// Get reviews for a specific user, paginated by cursor.
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  });

  /// Submit a review for a transaction. Idempotent by [ReviewSubmission.idempotencyKey].
  ///
  /// Throws on failure (network, conflict, validation, rate-limit).
  /// Retry budget: 3 retries on transient network error with exponential backoff;
  /// 0 retries on conflict/auth/validation/rate-limit.
  Future<ReviewEntity> submitReview(ReviewSubmission submission);

  /// Get reviews for a specific transaction (0, 1, or 2 items).
  ///
  /// Server filters [ReviewEntity.isHidden] per the requesting viewer —
  /// client receives only reviews it is allowed to see.
  Future<List<ReviewEntity>> getForTransaction(String transactionId);

  /// Get aggregate rating statistics for a user.
  ///
  /// Returns [ReviewAggregate.empty] for users with no reviews.
  Future<ReviewAggregate> getAggregateForUser(String userId);

  /// Report a review for DSA Art. 16 compliance.
  Future<void> reportReview(String reviewId, ReportReason reason);
}
