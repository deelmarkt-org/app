import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_state.dart';

part 'public_profile_notifier.g.dart';

/// ViewModel for the public seller profile screen (P-39).
///
/// Per-section independent [AsyncValue] — error in one section
/// does not block others (Tier-1 pattern, ref ProfileNotifier).
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
@riverpod
class PublicProfileNotifier extends _$PublicProfileNotifier {
  static const _reviewPageSize = 5;
  String? _reviewCursor;
  bool _hasMoreReviews = false;
  bool _isLoadingMore = false;

  @override
  PublicProfileState build(String userId) {
    load();
    return const PublicProfileState();
  }

  Future<void> load() async {
    final userRepo = ref.read(userRepositoryProvider);
    final reviewRepo = ref.read(reviewRepositoryProvider);
    final listingRepo = ref.read(listingRepositoryProvider);

    final userResult = await AsyncValue.guard(() => userRepo.getById(userId));
    if (userResult.valueOrNull == null) {
      state = PublicProfileState(
        user: userResult,
        aggregate: const AsyncValue.data(ReviewAggregate.empty('')),
        listings: const AsyncValue.data([]),
        reviews: const AsyncValue.data([]),
      );
      return;
    }

    final results = await Future.wait([
      AsyncValue.guard(() => reviewRepo.getAggregateForUser(userId)),
      AsyncValue.guard(() => listingRepo.getByUserId(userId)),
      AsyncValue.guard(() => reviewRepo.getByUserId(userId)),
    ]);

    final reviews = results[2] as AsyncValue<List<ReviewEntity>>;
    _hasMoreReviews = (reviews.valueOrNull?.length ?? 0) >= _reviewPageSize;
    if (reviews.hasValue && reviews.requireValue.isNotEmpty) {
      _reviewCursor = reviews.requireValue.last.id;
    }

    state = PublicProfileState(
      user: AsyncValue.data(userResult.requireValue),
      aggregate: results[0] as AsyncValue<ReviewAggregate>,
      listings: results[1] as AsyncValue<List<ListingEntity>>,
      reviews: reviews,
    );
  }

  Future<void> refresh() async {
    _reviewCursor = null;
    _hasMoreReviews = false;
    state = const PublicProfileState();
    await load();
  }

  bool get hasMoreReviews => _hasMoreReviews;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreReviews) return;
    _isLoadingMore = true;
    state = state.copyWith();

    final reviewRepo = ref.read(reviewRepositoryProvider);
    final result = await AsyncValue.guard(
      () => reviewRepo.getByUserId(userId, cursor: _reviewCursor),
    );

    _isLoadingMore = false;
    if (result.hasValue) {
      final newItems = result.requireValue;
      _hasMoreReviews = newItems.length >= _reviewPageSize;
      if (newItems.isNotEmpty) {
        _reviewCursor = newItems.last.id;
      }
      final existing = state.reviews.valueOrNull ?? [];
      state = state.copyWith(
        reviews: AsyncValue.data([...existing, ...newItems]),
      );
    }
  }

  void shareProfile() {
    final url = 'https://deelmarkt.com/users/$userId';
    Clipboard.setData(ClipboardData(text: url));
  }

  Future<void> reportUser(ReportReason reason) async {
    await ref.read(reviewRepositoryProvider).reportReview(userId, reason);
  }

  Future<void> reportReview(String reviewId, ReportReason reason) async {
    await ref.read(reviewRepositoryProvider).reportReview(reviewId, reason);
  }
}
