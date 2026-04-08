import 'dart:async';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_submission.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';

import '_settings_repo_stubs.dart' show testUser;

// ── User repository stubs ─────────────────────────────────────────────────────

/// User repository that returns a user instantly.
class InstantUserRepository implements UserRepository {
  const InstantUserRepository();

  @override
  Future<UserEntity?> getCurrentUser() async => testUser;

  @override
  Future<UserEntity?> getById(String id) async => testUser;

  @override
  Future<void> reportUser(String userId, ReportReason reason) async {}

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) async => testUser;
}

/// User repository that never finishes loading.
class HangingUserRepository implements UserRepository {
  @override
  Future<UserEntity?> getCurrentUser() => Completer<UserEntity?>().future;

  @override
  Future<UserEntity?> getById(String id) => Completer<UserEntity?>().future;

  @override
  Future<void> reportUser(String userId, ReportReason reason) async {}

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) => Completer<UserEntity>().future;
}

/// User repository that throws on getCurrentUser.
class ErrorUserRepository implements UserRepository {
  @override
  Future<UserEntity?> getCurrentUser() => throw Exception('Auth failed');

  @override
  Future<UserEntity?> getById(String id) => throw Exception('Auth failed');

  @override
  Future<void> reportUser(String userId, ReportReason reason) =>
      throw Exception('Auth failed');

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) => throw Exception('Auth failed');
}

/// User repository that returns null user.
class NullUserRepository implements UserRepository {
  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<UserEntity?> getById(String id) async => null;

  @override
  Future<void> reportUser(String userId, ReportReason reason) async {}

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) => throw Exception('No user');
}

// ── Listing & review repository stubs ────────────────────────────────────────

/// Stub listing repository that returns empty list instantly.
class EmptyListingRepository implements ListingRepository {
  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async => [];

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async => [];

  @override
  Future<ListingEntity?> getById(String id) async => null;

  @override
  Future<ListingSearchResult> search({
    required String query,
    String? categoryId,
    List<String>? categoryIds,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    String? sortBy,
    bool ascending = false,
    int offset = 0,
    int limit = 20,
  }) async =>
      const ListingSearchResult(listings: [], total: 0, offset: 0, limit: 20);

  @override
  Future<ListingEntity> toggleFavourite(String listingId) =>
      throw UnimplementedError();

  @override
  Future<List<ListingEntity>> getFavourites() async => [];

  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async => [];
}

/// Stub review repository that returns empty list instantly.
class EmptyReviewRepository implements ReviewRepository {
  @override
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  }) async => [];

  @override
  Future<ReviewEntity> submitReview(ReviewSubmission submission) =>
      throw UnimplementedError();

  @override
  Future<List<ReviewEntity>> getForTransaction(String transactionId) async =>
      [];

  @override
  Future<ReviewAggregate> getAggregateForUser(String userId) async =>
      ReviewAggregate.empty(userId);

  @override
  Future<void> reportReview(String reviewId, ReportReason reason) async {}
}
