import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_state.dart';

Future<ProviderContainer> _createContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      useMockDataProvider.overrideWithValue(true),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

Future<PublicProfileState> _waitForState(
  ProviderContainer container,
  String userId,
) async {
  container.listen(publicProfileNotifierProvider(userId), (_, _) {});
  await Future<void>.delayed(const Duration(milliseconds: 1000));
  return container.read(publicProfileNotifierProvider(userId));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PublicProfileNotifier', () {
    test('loads user-001 profile data', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-001');
      expect(state.user.hasValue, isTrue);
      final user = state.user.requireValue;
      expect(user, isNotNull);
      expect(user!.displayName, 'Jan de Vries');
      expect(user.location, 'Amsterdam');
    });

    test('loads aggregate rating data', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-001');
      expect(state.aggregate.hasValue, isTrue);
      final agg = state.aggregate.requireValue;
      expect(agg.userId, 'user-001');
    });

    test('loads listings data', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-001');
      expect(state.listings.hasValue, isTrue);
    });

    test('loads reviews data', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-001');
      expect(state.reviews.hasValue, isTrue);
    });

    test('non-existent user returns null user', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-nonexistent');
      expect(state.user.hasValue, isTrue);
      expect(state.user.requireValue, isNull);
    });

    test('user-003 has too-few reviews', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-003');
      expect(state.user.hasValue, isTrue);
      expect(state.user.requireValue!.reviewCount, 2);
    });

    test('user-004 profile loads correctly', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'user-004');
      expect(state.user.hasValue, isTrue);
      expect(state.user.requireValue!.displayName, 'Sophie van Dijk');
    });

    test('refresh resets and reloads state', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'user-001');

      final notifier = container.read(
        publicProfileNotifierProvider('user-001').notifier,
      );
      await notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 1000));

      final state = container.read(publicProfileNotifierProvider('user-001'));
      expect(state.user.hasValue, isTrue);
    });

    test(
      'per-section independence: user error does not block others',
      () async {
        final container = await _createContainer();
        addTearDown(container.dispose);

        final state = await _waitForState(container, 'user-nonexistent');
        // When user is null, others get empty data (not error)
        expect(state.listings.hasValue, isTrue);
        expect(state.reviews.hasValue, isTrue);
      },
    );
  });

  group('PublicProfileState', () {
    test('default state is all loading', () {
      const state = PublicProfileState();
      expect(state.user.isLoading, isTrue);
      expect(state.aggregate.isLoading, isTrue);
      expect(state.listings.isLoading, isTrue);
      expect(state.reviews.isLoading, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const state = PublicProfileState(
        user: AsyncValue.data(null),
        aggregate: AsyncValue.data(ReviewAggregate.empty('test')),
      );
      final updated = state.copyWith(
        user: AsyncValue.data(
          UserEntity(
            id: 'new',
            displayName: 'Test',
            kycLevel: KycLevel.level0,
            createdAt: DateTime(2025),
          ),
        ),
      );
      expect(updated.user.requireValue!.id, 'new');
      expect(updated.aggregate.hasValue, isTrue);
    });
  });
}
