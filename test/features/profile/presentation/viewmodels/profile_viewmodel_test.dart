import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';

/// Avatar upload service that always throws [Exception] to simulate failure.
class _ThrowingAvatarService implements AvatarUploadService {
  @override
  Future<String> upload({required String userId, required String filePath}) {
    throw Exception('Simulated upload failure');
  }
}

/// Creates a container with mock data, subscribes to keep the provider alive,
/// and waits for the initial load to complete.
Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer(
    overrides: [useMockDataProvider.overrideWithValue(true)],
  )..listen(profileNotifierProvider, (_, _) {});
  // User fetched first (200ms), then listings+reviews in parallel (≤500ms).
  await Future<void>.delayed(const Duration(milliseconds: 800));
  return container;
}

void main() {
  group('ProfileNotifier', () {
    test('load() populates user', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileNotifierProvider);
      expect(state.user.hasValue, isTrue);
      expect(state.user.requireValue, isNotNull);
    });

    test('load() populates listings', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileNotifierProvider);
      expect(state.listings.hasValue, isTrue);
      expect(state.listings.requireValue, isNotEmpty);
    });

    test('load() populates reviews', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(profileNotifierProvider);
      expect(state.reviews.hasValue, isTrue);
      expect(state.reviews.requireValue, isNotEmpty);
    });

    test('initial state is loading for all sections', () async {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      )..listen(profileNotifierProvider, (_, _) {});

      final state = container.read(profileNotifierProvider);
      expect(state.user.isLoading, isTrue);
      expect(state.listings.isLoading, isTrue);
      expect(state.reviews.isLoading, isTrue);

      // Wait for the background load() to finish before disposing,
      // otherwise the notifier tries to set state after disposal.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      container.dispose();
    });

    test('user entity has expected fields', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final user = container.read(profileNotifierProvider).user.requireValue!;
      expect(user.id, isNotEmpty);
      expect(user.displayName, isNotEmpty);
    });
  });

  group('ProfileState', () {
    test('copyWith returns new instance with updated fields', () {
      const state = ProfileState();
      final updated = state.copyWith(user: const AsyncValue.data(null));
      expect(updated.user.hasValue, isTrue);
      expect(updated.listings.isLoading, isTrue);
    });

    test('copyWith preserves existing values when not overridden', () {
      const state = ProfileState(listings: AsyncValue.data([]));
      final updated = state.copyWith(reviews: const AsyncValue.data([]));
      expect(updated.listings.hasValue, isTrue);
      expect(updated.reviews.hasValue, isTrue);
      expect(updated.user.isLoading, isTrue);
    });
  });

  group('reviewRepositoryProvider', () {
    test('returns a ReviewRepository instance', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      final repo = container.read(reviewRepositoryProvider);
      expect(repo, isNotNull);
    });
  });

  group('ProfileNotifier.uploadAvatar (#53)', () {
    test(
      'sets isUploadingAvatar true during upload then false on success',
      () async {
        final container = await _loadedContainer();
        addTearDown(container.dispose);

        var seenUploading = false;
        container.listen(profileNotifierProvider, (_, state) {
          if (state.isUploadingAvatar) seenUploading = true;
        });

        await container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar('/tmp/avatar.jpg');

        expect(seenUploading, isTrue);
        expect(
          container.read(profileNotifierProvider).isUploadingAvatar,
          isFalse,
        );
      },
    );

    test('uploadAvatar success updates user.avatarUrl in state', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final previousUrl =
          container.read(profileNotifierProvider).user.requireValue?.avatarUrl;

      await container
          .read(profileNotifierProvider.notifier)
          .uploadAvatar('/tmp/new_avatar.png');

      final updatedUrl =
          container.read(profileNotifierProvider).user.requireValue?.avatarUrl;

      // MockAvatarUploadService returns a fake Cloudinary URL containing
      // the userId; the mock user repo echo-returns it via updateProfile().
      expect(updatedUrl, isNotNull);
      expect(updatedUrl, isNot(equals(previousUrl)));
      expect(updatedUrl, startsWith('https://'));
    });

    test('uploadAvatar with null user throws StateError', () async {
      // Container with no load() completion — user is still null.
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          // Override with a service that would succeed if user existed.
          avatarUploadServiceProvider.overrideWithValue(
            MockAvatarUploadService(),
          ),
        ],
      )..listen(profileNotifierProvider, (_, _) {});
      addTearDown(container.dispose);

      // Read immediately before the async load() populates user.
      // The notifier starts with user = AsyncValue.loading(), so userId is null.
      expect(
        () => container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar('/tmp/avatar.jpg'),
        throwsA(isA<StateError>()),
      );
    });

    test('isUploadingAvatar defaults to false in initial ProfileState', () {
      const state = ProfileState();
      expect(state.isUploadingAvatar, isFalse);
    });

    test('uploadAvatar failure reverts avatarUrl to previous value', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          avatarUploadServiceProvider.overrideWithValue(
            _ThrowingAvatarService(),
          ),
        ],
      )..listen(profileNotifierProvider, (_, _) {});
      addTearDown(container.dispose);

      // Wait for the initial load to populate user.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final previousUrl =
          container.read(profileNotifierProvider).user.requireValue?.avatarUrl;

      // uploadAvatar rethrows after reverting — catch to inspect state.
      await expectLater(
        () => container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar('/tmp/avatar.jpg'),
        throwsException,
      );

      final afterUrl =
          container.read(profileNotifierProvider).user.requireValue?.avatarUrl;

      expect(afterUrl, equals(previousUrl));
      expect(
        container.read(profileNotifierProvider).isUploadingAvatar,
        isFalse,
      );
    });
  });
}
