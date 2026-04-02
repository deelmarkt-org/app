import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';

/// In-memory mock for development when Supabase reviews table isn't ready.
///
/// Returns hardcoded reviews after a simulated network delay.
/// Toggle via provider override in dev builds.
class MockReviewRepository implements ReviewRepository {
  MockReviewRepository() {
    if (kReleaseMode) {
      throw StateError('MockReviewRepository cannot be used in release builds');
    }
  }

  @override
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _mockReviews.take(limit).toList();
  }
}

/// Mock user ID used as the reviewee across all test reviews.
const _mockRevieweeId = 'user-001';

final _mockReviews = [
  ReviewEntity(
    id: 'review-001',
    reviewerId: 'user-002',
    reviewerName: 'Maria Jansen',
    revieweeId: _mockRevieweeId,
    listingId: 'listing-001',
    rating: 5.0,
    text: 'Snelle verzending en precies zoals beschreven. Top verkoper!',
    createdAt: DateTime(2026, 3, 15),
  ),
  ReviewEntity(
    id: 'review-002',
    reviewerId: 'user-003',
    reviewerName: 'Pieter Bakker',
    revieweeId: _mockRevieweeId,
    listingId: 'listing-002',
    rating: 4.0,
    text: 'Goede communicatie, item was in orde. Aanrader.',
    createdAt: DateTime(2026, 3, 10),
  ),
  ReviewEntity(
    id: 'review-003',
    reviewerId: 'user-004',
    reviewerName: 'Sophie Visser',
    revieweeId: _mockRevieweeId,
    listingId: 'listing-003',
    rating: 4.5,
    text: 'Fijne transactie, goed verpakt. Bedankt!',
    createdAt: DateTime(2026, 3, 5),
  ),
];
