import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';

/// Independent async state for each profile section.
///
/// Per Tier-1 audit: error in one section must not block others.
class ProfileState {
  const ProfileState({
    this.user = const AsyncValue.loading(),
    this.listings = const AsyncValue.loading(),
    this.reviews = const AsyncValue.loading(),
  });

  final AsyncValue<UserEntity?> user;
  final AsyncValue<List<ListingEntity>> listings;
  final AsyncValue<List<ReviewEntity>> reviews;

  ProfileState copyWith({
    AsyncValue<UserEntity?>? user,
    AsyncValue<List<ListingEntity>>? listings,
    AsyncValue<List<ReviewEntity>>? reviews,
  }) {
    return ProfileState(
      user: user ?? this.user,
      listings: listings ?? this.listings,
      reviews: reviews ?? this.reviews,
    );
  }
}

/// ViewModel for the own profile screen.
///
/// Loads user, listings, and reviews as independent [AsyncValue]s
/// so partial data renders and one failure doesn't block others.
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({required Ref ref})
    : _ref = ref,
      super(const ProfileState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    final userRepo = _ref.read(userRepositoryProvider);
    final listingRepo = _ref.read(listingRepositoryProvider);
    final reviewRepo = _ref.read(reviewRepositoryProvider);

    // Load all three in parallel, each independent
    final userFuture = AsyncValue.guard(() => userRepo.getCurrentUser());
    final listingsFuture = AsyncValue.guard(() async {
      final user = await userRepo.getCurrentUser();
      if (user == null) return <ListingEntity>[];
      return listingRepo.getByUserId(user.id);
    });
    final reviewsFuture = AsyncValue.guard(() async {
      final user = await userRepo.getCurrentUser();
      if (user == null) return <ReviewEntity>[];
      return reviewRepo.getByUserId(user.id);
    });

    final results = await Future.wait([
      userFuture,
      listingsFuture,
      reviewsFuture,
    ]);
    state = ProfileState(
      user: results[0] as AsyncValue<UserEntity?>,
      listings: results[1] as AsyncValue<List<ListingEntity>>,
      reviews: results[2] as AsyncValue<List<ReviewEntity>>,
    );
  }
}

/// Review repository provider — mock or real.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  // TODO(reso): Add SupabaseReviewRepository when reviews table is ready
  return MockReviewRepository();
});

/// Profile viewmodel provider.
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref: ref),
);
