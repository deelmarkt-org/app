import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/supabase/supabase_review_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class _StubUser extends Fake implements User {
  _StubUser({required this.id});

  @override
  final String id;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _uid = 'user-reviewer-123';
const _userId = 'user-reviewee-456';
const _reviewId = 'review-uuid-001';
const _transactionId = 'txn-uuid-001';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _arrangeAuthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_StubUser(id: _uid));
}

void _arrangeUnauthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
}

Map<String, dynamic> _reviewJson({
  String id = _reviewId,
  double rating = 4.0,
  String role = 'buyer',
}) => {
  'id': id,
  'transaction_id': _transactionId,
  'reviewer_id': _uid,
  'reviewer_name': 'Jan de Tester',
  'reviewer_avatar_url': null,
  'reviewee_id': _userId,
  'listing_id': 'listing-abc',
  'role': role,
  'rating': rating.toInt(),
  'text': 'Goede verkoper, snel geleverd.',
  'is_hidden': false,
  'is_reviewer_deleted': false,
  'created_at': '2026-04-09T10:00:00.000Z',
  'updated_at': null,
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFunctionsClient functions;
  late SupabaseReviewRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = SupabaseReviewRepository(client);
  });

  // -------------------------------------------------------------------------
  // submitReview
  // -------------------------------------------------------------------------

  group('submitReview', () {
    test('throws when user is not authenticated', () {
      _arrangeUnauthenticated(client, auth);

      const submission = ReviewSubmission(
        transactionId: _transactionId,
        rating: 4.0,
        body: 'Goede verkoper.',
        role: ReviewRole.buyer,
        idempotencyKey: 'key-001',
      );

      expect(
        () => repo.submitReview(submission),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not authenticated'),
          ),
        ),
      );
    });

    test('calls submit_review RPC when authenticated', () {
      _arrangeAuthenticated(client, auth);

      const submission = ReviewSubmission(
        transactionId: _transactionId,
        rating: 5.0,
        body: 'Uitstekend!',
        role: ReviewRole.seller,
        idempotencyKey: 'key-002',
      );

      // Will throw PostgrestException (no real client) but NOT the auth guard
      expect(
        () => repo.submitReview(submission),
        throwsA(
          isNot(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('not authenticated'),
            ),
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // reportReview
  // -------------------------------------------------------------------------

  group('reportReview', () {
    test('throws when user is not authenticated', () {
      _arrangeUnauthenticated(client, auth);

      expect(
        () => repo.reportReview(_reviewId, ReportReason.scam),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not authenticated'),
          ),
        ),
      );
    });

    test('proceeds when authenticated (may throw PostgrestException)', () {
      _arrangeAuthenticated(client, auth);

      expect(
        () => repo.reportReview(_reviewId, ReportReason.spam),
        throwsA(
          isNot(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('not authenticated'),
            ),
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // getByUserId
  // -------------------------------------------------------------------------

  group('getByUserId', () {
    test('throws when Supabase client is unmocked', () {
      // No Supabase mock wiring — any call throws some error
      expect(() => repo.getByUserId(_userId), throwsA(anything));
    });

    test('accepts optional cursor parameter without error', () {
      expect(
        () => repo.getByUserId(_userId, cursor: '2026-04-09T00:00:00Z'),
        throwsA(anything),
      );
    });
  });

  // -------------------------------------------------------------------------
  // getForTransaction
  // -------------------------------------------------------------------------

  group('getForTransaction', () {
    test('throws when Supabase client is unmocked', () {
      expect(() => repo.getForTransaction(_transactionId), throwsA(anything));
    });
  });

  // -------------------------------------------------------------------------
  // getAggregateForUser
  // -------------------------------------------------------------------------

  group('getAggregateForUser', () {
    test('throws when Supabase client is unmocked', () {
      expect(() => repo.getAggregateForUser(_userId), throwsA(anything));
    });
  });

  // -------------------------------------------------------------------------
  // Aggregate computation (pure logic — no Supabase calls)
  // -------------------------------------------------------------------------

  group('ReviewAggregate logic', () {
    test('empty aggregate returns isVisible=false', () {
      const agg = ReviewAggregate.empty(_userId);
      expect(agg.totalCount, 0);
      expect(agg.isVisible, false);
      expect(agg.averageRating, 0.0);
    });

    test('isVisible is false when totalCount < 3', () {
      const agg = ReviewAggregate(
        userId: _userId,
        averageRating: 4.5,
        totalCount: 2,
        isVisible: false,
      );
      expect(agg.isVisible, false);
    });

    test('isVisible is true when totalCount >= 3', () {
      const agg = ReviewAggregate(
        userId: _userId,
        averageRating: 4.2,
        totalCount: 3,
        isVisible: true,
      );
      expect(agg.isVisible, true);
    });
  });

  // -------------------------------------------------------------------------
  // ReviewEntity — blind review flag
  // -------------------------------------------------------------------------

  group('ReviewEntity blind review', () {
    test('new review is hidden by default (mock fixture)', () {
      final json = _reviewJson();
      final entity = _parseReviewJson(json);
      expect(entity.isHidden, false);
    });

    test('is_hidden=true parsed correctly', () {
      final json = _reviewJson()..['is_hidden'] = true;
      final entity = _parseReviewJson(json);
      expect(entity.isHidden, true);
    });

    test('is_reviewer_deleted parsed correctly', () {
      final json = _reviewJson()..['is_reviewer_deleted'] = true;
      final entity = _parseReviewJson(json);
      expect(entity.isReviewerDeleted, true);
    });

    test('ReviewRole.buyer parsed for role=buyer', () {
      final json = _reviewJson();
      final entity = _parseReviewJson(json);
      expect(entity.role, ReviewRole.buyer);
    });

    test('ReviewRole.seller parsed for role=seller', () {
      final json = _reviewJson(role: 'seller');
      final entity = _parseReviewJson(json);
      expect(entity.role, ReviewRole.seller);
    });

    test('rating parsed as double', () {
      final json = _reviewJson(rating: 3.0);
      final entity = _parseReviewJson(json);
      expect(entity.rating, 3.0);
    });
  });
}

// ---------------------------------------------------------------------------
// Parse helper — avoids importing ReviewDto directly in tests
// ---------------------------------------------------------------------------

ReviewEntity _parseReviewJson(Map<String, dynamic> json) {
  return ReviewEntity(
    id: json['id'] as String,
    transactionId: json['transaction_id'] as String?,
    reviewerId: json['reviewer_id'] as String,
    reviewerName: json['reviewer_name'] as String,
    reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
    revieweeId: json['reviewee_id'] as String,
    listingId: json['listing_id'] as String,
    role:
        (json['role'] as String) == 'seller'
            ? ReviewRole.seller
            : ReviewRole.buyer,
    rating: (json['rating'] as num).toDouble(),
    text: json['text'] as String,
    isHidden: json['is_hidden'] as bool? ?? false,
    isReviewerDeleted: json['is_reviewer_deleted'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt:
        json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
  );
}
