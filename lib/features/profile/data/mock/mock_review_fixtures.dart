import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// Mock data fixtures for [MockReviewRepository].
///
/// Separated from mock_review_repository.dart to stay under 200-line limit.

/// Mock user ID used as the current user in test/dev.
const mockCurrentUserId = 'user-current';

/// Mock reviewee ID (the seller being reviewed).
const mockRevieweeId = 'user-001';

/// Mock seller user ID used in transaction-level fixtures.
const mockSellerId = 'user-seller';

/// Transaction ID shared across the "both visible" fixture set.
const _txn003 = 'txn-003';

/// Base review fixtures used by getByUserId.
final mockReviews = [
  ReviewEntity(
    id: 'review-001',
    transactionId: _txn003,
    reviewerId: 'user-002',
    reviewerName: 'Maria Jansen',
    revieweeId: mockRevieweeId,
    listingId: 'listing-001',
    rating: 5.0,
    body: 'Snelle verzending en precies zoals beschreven. Top verkoper!',
    createdAt: DateTime(2026, 3, 15),
  ),
  ReviewEntity(
    id: 'review-002',
    transactionId: _txn003,
    reviewerId: 'user-003',
    reviewerName: 'Pieter Bakker',
    revieweeId: mockRevieweeId,
    listingId: 'listing-002',
    rating: 4.0,
    body: 'Goede communicatie, item was in orde. Aanrader.',
    createdAt: DateTime(2026, 3, 10),
  ),
  ReviewEntity(
    id: 'review-003',
    transactionId: _txn003,
    reviewerId: 'user-004',
    reviewerName: 'Sophie Visser',
    revieweeId: mockRevieweeId,
    listingId: 'listing-003',
    role: ReviewRole.seller,
    rating: 4.5,
    body: 'Fijne transactie, goed verpakt. Bedankt!',
    createdAt: DateTime(2026, 3, 5),
  ),
];

/// Transaction-level fixtures for getForTransaction.
///
/// - txn-001: empty (draft state)
/// - txn-002: one review by current user (waiting state)
/// - txn-003: both reviews submitted (bothVisible state)
final mockTxnFixtures = <String, List<ReviewEntity>>{
  'txn-001': [],
  'txn-002': [
    ReviewEntity(
      id: 'review-txn2-mine',
      transactionId: 'txn-002',
      reviewerId: mockCurrentUserId,
      reviewerName: 'Current User',
      revieweeId: mockSellerId,
      listingId: 'listing-010',
      rating: 4.0,
      body: 'Goede verkoper, netjes verpakt.',
      createdAt: DateTime(2026, 4, 2),
    ),
  ],
  _txn003: [
    ReviewEntity(
      id: 'review-txn3-buyer',
      transactionId: _txn003,
      reviewerId: mockCurrentUserId,
      reviewerName: 'Current User',
      revieweeId: mockSellerId,
      listingId: 'listing-020',
      rating: 5.0,
      body: 'Uitstekende ervaring, snelle levering!',
      createdAt: DateTime(2026, 4, 3),
    ),
    ReviewEntity(
      id: 'review-txn3-seller',
      transactionId: _txn003,
      reviewerId: mockSellerId,
      reviewerName: 'Jan de Vries',
      revieweeId: mockCurrentUserId,
      listingId: 'listing-020',
      role: ReviewRole.seller,
      rating: 5.0,
      body: 'Prettige koper, snelle betaling.',
      createdAt: DateTime(2026, 4, 3),
    ),
  ],
};
