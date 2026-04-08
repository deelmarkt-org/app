import 'package:equatable/equatable.dart';

/// Aggregate rating statistics for a user.
///
/// Used by [RatingDisplay] to show the average, count, and visibility gate.
/// [isVisible] is server-authoritative; client falls back to `totalCount >= 3`.
///
/// Reference: docs/epics/E06-trust-moderation.md lines 79–80
class ReviewAggregate extends Equatable {
  const ReviewAggregate({
    required this.userId,
    required this.averageRating,
    required this.totalCount,
    required this.isVisible,
    this.distribution = const {},
    this.lastReviewAt,
  });

  /// Empty aggregate for a user with no reviews.
  const ReviewAggregate.empty(this.userId)
    : averageRating = 0,
      totalCount = 0,
      isVisible = false,
      distribution = const {},
      lastReviewAt = null;

  final String userId;

  /// Average rating (1.0–5.0). Zero if no reviews.
  final double averageRating;

  /// Total number of reviews received.
  final int totalCount;

  /// Whether the aggregate should be displayed publicly.
  /// Server-authoritative; hidden when count < 3 to prevent gaming.
  final bool isVisible;

  /// Rating distribution: {5: 8, 4: 3, 3: 1, 2: 0, 1: 0}.
  final Map<int, int> distribution;

  /// Timestamp of the most recent review.
  final DateTime? lastReviewAt;

  @override
  List<Object?> get props => [
    userId,
    averageRating,
    totalCount,
    isVisible,
    distribution,
    lastReviewAt,
  ];
}
