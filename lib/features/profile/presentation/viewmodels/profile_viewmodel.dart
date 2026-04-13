import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
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
    this.isUploadingAvatar = false,
  });

  final AsyncValue<UserEntity?> user;
  final AsyncValue<List<ListingEntity>> listings;
  final AsyncValue<List<ReviewEntity>> reviews;
  final bool isUploadingAvatar;

  ProfileState copyWith({
    AsyncValue<UserEntity?>? user,
    AsyncValue<List<ListingEntity>>? listings,
    AsyncValue<List<ReviewEntity>>? reviews,
    bool? isUploadingAvatar,
  }) {
    return ProfileState(
      user: user ?? this.user,
      listings: listings ?? this.listings,
      reviews: reviews ?? this.reviews,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
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

  /// Uploads a new avatar image and updates the user profile.
  ///
  /// Sets [isUploadingAvatar] during the upload. On failure,
  /// reverts [user.avatarUrl] to the previous value.
  Future<void> uploadAvatar(String imagePath) async {
    final previousUrl = state.user.valueOrNull?.avatarUrl;
    state = state.copyWith(isUploadingAvatar: true);

    try {
      final userId = state.user.valueOrNull?.id;
      if (userId == null) {
        throw StateError('Cannot upload avatar: user not loaded');
      }

      final service = ref.read(avatarUploadServiceProvider);
      final publicUrl = await service.upload(
        userId: userId,
        filePath: imagePath,
      );

      final userRepo = ref.read(userRepositoryProvider);
      final updated = await userRepo.updateProfile(avatarUrl: publicUrl);

      state = state.copyWith(
        user: AsyncValue.data(updated),
        isUploadingAvatar: false,
      );
    } on Exception {
      final currentUser = state.user.valueOrNull;
      if (currentUser != null) {
        state = state.copyWith(
          user: AsyncValue.data(currentUser.copyWith(avatarUrl: previousUrl)),
          isUploadingAvatar: false,
        );
      } else {
        state = state.copyWith(isUploadingAvatar: false);
      }
      rethrow;
    }
  }
}
