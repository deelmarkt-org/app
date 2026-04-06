import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_review_fixtures.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';

/// In-memory mock for development when Supabase reviews table isn't ready.
///
/// Returns hardcoded reviews after a simulated network delay.
/// Toggle via provider override in dev builds (ADR-MOCK-SWAP).
class MockReviewRepository implements ReviewRepository {
  MockReviewRepository() {
    if (kReleaseMode) {
      throw StateError('MockReviewRepository cannot be used in release builds');
    }
  }

  final List<ReviewEntity> _submitted = [];
  final Set<String> _idempotencyKeys = {};

  @override
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  }) async {
    await _simulateDelay();
    final all =
        [
          ...mockReviews,
          ..._submitted,
        ].where((r) => r.revieweeId == userId).toList();
    return all.take(limit).toList();
  }

  @override
  Future<ReviewEntity> submitReview(ReviewSubmission submission) async {
    await _simulateDelay();

    if (_idempotencyKeys.contains(submission.idempotencyKey)) {
      return _submitted.firstWhere(
        (r) => r.transactionId == submission.transactionId,
      );
    }

    final review = ReviewEntity(
      id: 'review-new-${_submitted.length + 1}',
      transactionId: submission.transactionId,
      reviewerId: mockCurrentUserId,
      reviewerName: 'Current User',
      revieweeId: 'user-other',
      listingId: 'listing-001',
      role: submission.role,
      rating: submission.rating,
      text: submission.body,
      isHidden: true,
      createdAt: DateTime.now(),
    );

    _submitted.add(review);
    _idempotencyKeys.add(submission.idempotencyKey);
    return review;
  }

  @override
  Future<List<ReviewEntity>> getForTransaction(String transactionId) async {
    await _simulateDelay();
    return mockTxnFixtures[transactionId] ??
        _submitted.where((r) => r.transactionId == transactionId).toList();
  }

  @override
  Future<ReviewAggregate> getAggregateForUser(String userId) async {
    await _simulateDelay();
    final reviews =
        [
          ...mockReviews,
          ..._submitted,
        ].where((r) => r.revieweeId == userId).toList();

    if (reviews.isEmpty) {
      return ReviewAggregate.empty(userId);
    }

    final sum = reviews.fold<double>(0, (s, r) => s + r.rating);
    final count = reviews.length;
    final distribution = <int, int>{};
    for (final r in reviews) {
      final bucket = r.rating.round();
      distribution[bucket] = (distribution[bucket] ?? 0) + 1;
    }

    return ReviewAggregate(
      userId: userId,
      averageRating: sum / count,
      totalCount: count,
      isVisible: count >= 3,
      distribution: distribution,
      lastReviewAt: reviews.first.createdAt,
    );
  }

  @override
  Future<void> reportReview(String reviewId, ReportReason reason) async {
    await _simulateDelay();
  }

  Future<void> _simulateDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
