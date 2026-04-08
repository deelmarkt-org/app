import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// Command object for submitting a review.
///
/// [idempotencyKey] is generated once at draft creation time and persisted
/// across retries to prevent duplicate submissions. Reuse the same key on
/// retry to guarantee at-most-once semantics.
///
/// Reference: docs/epics/E06-trust-moderation.md §Ratings & Reviews
class ReviewSubmission {
  const ReviewSubmission({
    required this.transactionId,
    required this.rating,
    required this.body,
    required this.role,
    required this.idempotencyKey,
  });

  final String transactionId;

  /// 1.0–5.0 star rating (whole stars only for MVP).
  final double rating;

  /// Free-text review body, max 500 characters.
  final String body;

  /// Role of the reviewer in this transaction.
  final ReviewRole role;

  /// Client-generated unique key for idempotent submission.
  final String idempotencyKey;
}
