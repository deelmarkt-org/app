import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/dto/review_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';

/// Supabase implementation of [ReviewRepository].
///
/// Blind review logic is enforced at the DB level via RLS (migration R-36).
/// A review is only visible to non-reviewers once BOTH parties have submitted.
///
/// Reference: docs/epics/E06-trust-moderation.md §Ratings & Reviews
/// Reference: docs/SPRINT-PLAN.md R-36
class SupabaseReviewRepository implements ReviewRepository {
  const SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  static const _reviews = 'reviews';
  static const _reviewReports = 'review_reports';
  static const _createdAt = 'created_at';

  @override
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  }) async {
    try {
      var filter = _client
          .from(_reviews)
          .select()
          .eq('reviewee_id', userId)
          .eq('is_hidden', false);

      if (cursor != null) {
        filter = filter.lt(_createdAt, cursor);
      }

      final response = await filter
          .order(_createdAt, ascending: false)
          .limit(limit);
      return ReviewDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch reviews for user $userId: ${e.message}');
    }
  }

  /// Submits a review via the [submit_review] RPC for atomic transaction lookup.
  ///
  /// Idempotent: a duplicate submission (same transaction_id + reviewer_id)
  /// returns the existing review row without error.
  @override
  Future<ReviewEntity> submitReview(ReviewSubmission submission) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot submit review: user is not authenticated');
    }

    // Fetch reviewer display name + avatar for denormalisation
    final profile = await _fetchProfile(userId);

    try {
      final response = await _client.rpc(
        'submit_review',
        params: {
          'p_transaction_id': submission.transactionId,
          'p_role': submission.role.name,
          'p_rating': submission.rating.round(),
          'p_body': submission.body,
          'p_reviewer_name': profile['display_name'] as String? ?? '',
          'p_reviewer_avatar_url': profile['avatar_url'],
        },
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        throw Exception('submit_review RPC returned no rows');
      }
      return ReviewDto.fromJson(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit review: ${e.message}');
    }
  }

  @override
  Future<List<ReviewEntity>> getForTransaction(String transactionId) async {
    try {
      final response = await _client
          .from(_reviews)
          .select()
          .eq('transaction_id', transactionId)
          .order(_createdAt);

      return ReviewDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to fetch reviews for transaction $transactionId: ${e.message}',
      );
    }
  }

  /// Computes aggregate rating stats for [userId] via the server-side
  /// [get_review_aggregate] RPC (migration R-36), which avoids fetching
  /// unbounded rows client-side.
  ///
  /// [ReviewAggregate.isVisible] is true only when totalCount >= 3,
  /// matching the E06 spec: "average displayed once ≥3 reviews".
  @override
  Future<ReviewAggregate> getAggregateForUser(String userId) async {
    try {
      final response = await _client.rpc(
        'get_review_aggregate',
        params: {'p_user_id': userId},
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) return ReviewAggregate.empty(userId);

      final row = rows.first as Map<String, dynamic>;
      final count = (row['total_count'] as num?)?.toInt() ?? 0;
      if (count == 0) return ReviewAggregate.empty(userId);

      final avg = (row['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final distribution = <int, int>{
        1: (row['dist_1'] as num?)?.toInt() ?? 0,
        2: (row['dist_2'] as num?)?.toInt() ?? 0,
        3: (row['dist_3'] as num?)?.toInt() ?? 0,
        4: (row['dist_4'] as num?)?.toInt() ?? 0,
        5: (row['dist_5'] as num?)?.toInt() ?? 0,
      };
      final rawLastAt = row['last_review_at'] as String?;
      final lastReviewAt =
          rawLastAt != null ? DateTime.tryParse(rawLastAt) : null;

      return ReviewAggregate(
        userId: userId,
        averageRating: avg,
        totalCount: count,
        isVisible: count >= 3,
        distribution: distribution,
        lastReviewAt: lastReviewAt,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to fetch review aggregate for user $userId: ${e.message}',
      );
    }
  }

  @override
  Future<void> reportReview(String reviewId, ReportReason reason) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot report review: user is not authenticated');
    }

    try {
      await _client.from(_reviewReports).insert({
        'review_id': reviewId,
        'reporter_id': userId,
        'reason': reason.name,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to report review $reviewId: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    try {
      final response =
          await _client
              .from('user_profiles')
              .select('display_name, avatar_url')
              .eq('id', userId)
              .single();
      return response;
    } on PostgrestException catch (e) {
      // Non-fatal: reviewer profile missing → review still submits with empty name.
      // Log for observability (Sentry via R-12 integration picks this up).
      // ignore: avoid_print
      print(
        '[SupabaseReviewRepository] _fetchProfile failed for $userId: ${e.message}',
      );
      return {'display_name': '', 'avatar_url': null};
    }
  }
}
