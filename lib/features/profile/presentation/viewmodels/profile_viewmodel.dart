import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

part 'profile_viewmodel.g.dart';

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
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    load();
    return const ProfileState();
  }

  Future<void> load() async {
    final userRepo = ref.read(userRepositoryProvider);
    final listingRepo = ref.read(listingRepositoryProvider);
    final reviewRepo = ref.read(reviewRepositoryProvider);

    final userResult = await AsyncValue.guard(() => userRepo.getCurrentUser());
    final user = userResult.valueOrNull;

    if (user == null) {
      state = ProfileState(
        user: userResult,
        listings: const AsyncValue.data([]),
        reviews: const AsyncValue.data([]),
      );
      return;
    }

    final results = await Future.wait([
      AsyncValue.guard(() => listingRepo.getByUserId(user.id)),
      AsyncValue.guard(() => reviewRepo.getByUserId(user.id)),
    ]);

    state = ProfileState(
      user: AsyncValue.data(user),
      listings: results[0] as AsyncValue<List<ListingEntity>>,
      reviews: results[1] as AsyncValue<List<ReviewEntity>>,
    );
  }
}
