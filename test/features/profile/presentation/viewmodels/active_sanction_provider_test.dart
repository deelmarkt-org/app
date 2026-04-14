/// Tests for [ActiveSanctionProvider] (P-53 Phase G).
///
/// Reference: lib/features/profile/presentation/viewmodels/active_sanction_provider.dart
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_sanction_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);

  @override
  final String id;
}

/// Minimal sanction used across tests.
SanctionEntity _mockSanction({String userId = 'user-123'}) => SanctionEntity(
  id: 'sanction-001',
  userId: userId,
  type: SanctionType.suspension,
  reason: 'Test suspension',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6)),
);

/// Creates a [ProviderContainer] with the given [overrides] and subscribes to
/// [activeSanctionProvider] so the provider is kept alive during the test.
ProviderContainer _makeContainer({required List<Override> overrides}) {
  final container = ProviderContainer(overrides: overrides)
    ..listen(activeSanctionProvider, (prev, next) {});
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUser('fallback'));
  });

  group('ActiveSanctionProvider — logged-out user', () {
    test('returns null when currentUserProvider is null', () async {
      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(
            MockSanctionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(activeSanctionProvider.future);
      expect(result, isNull);
    });
  });

  group('ActiveSanctionProvider — feature flag disabled', () {
    test('returns null even if repository would return data', () async {
      final repo = _MockSanctionRepository();
      when(
        () => repo.getActiveSanction(any()),
      ).thenAnswer((_) async => _mockSanction());

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(false),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(activeSanctionProvider.future);
      expect(result, isNull);
      // Repository should NOT have been called.
      verifyNever(() => repo.getActiveSanction(any()));
    });
  });

  group('ActiveSanctionProvider — active sanction', () {
    test('emits AsyncData with sanction when repository returns one', () async {
      final sanction = _mockSanction();
      final repo = _MockSanctionRepository();
      when(
        () => repo.getActiveSanction('user-123'),
      ).thenAnswer((_) async => sanction);

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(activeSanctionProvider.future);
      expect(result, equals(sanction));
    });

    test('emits AsyncData(null) when repository returns null', () async {
      final repo = _MockSanctionRepository();
      when(
        () => repo.getActiveSanction('user-123'),
      ).thenAnswer((_) async => null);

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(activeSanctionProvider.future);
      expect(result, isNull);
    });
  });

  group('ActiveSanctionProvider — error handling', () {
    test('emits AsyncError when repository throws SanctionException', () async {
      final repo = _MockSanctionRepository();
      when(
        () => repo.getActiveSanction(any()),
      ).thenThrow(const SanctionNotFound());

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeSanctionProvider.future),
        throwsA(isA<SanctionNotFound>()),
      );
    });

    test('emits AsyncError when repository throws generic Exception', () async {
      final repo = _MockSanctionRepository();
      when(() => repo.getActiveSanction(any())).thenThrow(Exception('network'));

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeSanctionProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ActiveSanctionProvider — refresh()', () {
    test('re-invokes repository and emits new value', () async {
      var callCount = 0;
      final repo = _MockSanctionRepository();
      when(() => repo.getActiveSanction('user-123')).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return _mockSanction();
        return null; // second call returns null (sanction lifted)
      });

      final container = _makeContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_FakeUser('user-123')),
          isFeatureEnabledProvider(
            FeatureFlags.p53SuspensionGate,
          ).overrideWithValue(true),
          sanctionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final first = await container.read(activeSanctionProvider.future);
      expect(first, isNotNull);

      await container.read(activeSanctionProvider.notifier).refresh();

      final second = await container.read(activeSanctionProvider.future);
      expect(second, isNull);
      expect(callCount, 2);
    });
  });
}
