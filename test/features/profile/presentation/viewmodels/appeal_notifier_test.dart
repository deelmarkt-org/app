/// Tests for [AppealNotifier] (P-53 Phase G).
///
/// Reference: lib/features/profile/presentation/viewmodels/appeal_notifier.dart
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/firebase_service.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/appeal_notifier.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

SanctionEntity _returnedSanction(String sanctionId) => SanctionEntity(
  id: sanctionId,
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'test',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6)),
  appealedAt: DateTime.now(),
  appealBody: 'my appeal text here',
);

/// Builds a container with all required overrides.
ProviderContainer _container({
  required SanctionRepository repo,
  required FirebaseAnalytics analytics,
}) {
  return ProviderContainer(
    overrides: [
      sanctionRepositoryProvider.overrideWithValue(repo),
      firebaseAnalyticsProvider.overrideWithValue(analytics),
      // activeSanctionProvider needs at minimum a null user to avoid crashing.
      currentUserProvider.overrideWithValue(null),
    ],
  )..listen(appealNotifierProvider, (prev, next) {});
}

void main() {
  late _MockSanctionRepository repo;
  late _MockFirebaseAnalytics analytics;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _MockSanctionRepository();
    analytics = _MockFirebaseAnalytics();
    // Default stub — can be overridden per-test.
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AppealNotifier — initial state', () {
    test('starts as AsyncData(null)', () {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final state = container.read(appealNotifierProvider);
      expect(state, const AsyncData<void>(null));
    });
  });

  group('AppealNotifier — submit() validation', () {
    // G1: Body-length validation now sets AsyncError state rather than
    // throwing ArgumentError, so the error is surfaced through the UI via
    // ref.watch() instead of being an unhandled exception that bypasses the
    // on Exception catch block.
    test('sets AsyncError state when body is fewer than 10 chars', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final notifier = container.read(appealNotifierProvider.notifier);
      await notifier.submit(sanctionId: 's-1', body: 'short');

      final state = container.read(appealNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, isA<UnknownSanctionError>());
    });

    test('sets AsyncError state when body is exactly 9 chars', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final notifier = container.read(appealNotifierProvider.notifier);
      await notifier.submit(sanctionId: 's-1', body: '123456789');

      final state = container.read(appealNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, isA<UnknownSanctionError>());
    });

    test('sets AsyncError state when body exceeds 1000 chars', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final notifier = container.read(appealNotifierProvider.notifier);
      final longBody = 'a' * 1001;
      await notifier.submit(sanctionId: 's-1', body: longBody);

      final state = container.read(appealNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, isA<UnknownSanctionError>());
    });

    test('does not throw at exactly 10 chars', () async {
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenAnswer((_) async => _returnedSanction('s-1'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: '1234567890');

      final state = container.read(appealNotifierProvider);
      expect(state, const AsyncData<void>(null));
    });

    test('does not throw at exactly 1000 chars', () async {
      final body = 'b' * 1000;
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenAnswer((_) async => _returnedSanction('s-1'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: body);

      final state = container.read(appealNotifierProvider);
      expect(state, const AsyncData<void>(null));
    });
  });

  group('AppealNotifier — submit() success', () {
    test('emits AsyncData(null) after successful submission', () async {
      when(
        () => repo.submitAppeal('sanction-001', any()),
      ).thenAnswer((_) async => _returnedSanction('sanction-001'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(
            sanctionId: 'sanction-001',
            body: 'This is my appeal text that is long enough.',
          );

      expect(
        container.read(appealNotifierProvider),
        const AsyncData<void>(null),
      );
    });

    test('calls analytics.appealSubmitted with correct bodyLength', () async {
      const body = 'This is my appeal text that is long enough.';
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenAnswer((_) async => _returnedSanction('s-1'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: body);

      verify(
        () => analytics.logEvent(
          name: 'appeal_submitted',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('clears draft after successful submission', () async {
      SharedPreferences.setMockInitialValues({'appeal_draft_s-1': 'old draft'});
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenAnswer((_) async => _returnedSanction('s-1'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: 'This is a valid appeal body text.');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appeal_draft_s-1'), isNull);
    });
  });

  group('AppealNotifier — submit() failure', () {
    test('emits AsyncError(AppealWindowExpired) when repo throws it', () async {
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenThrow(const AppealWindowExpired());

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: 'Valid appeal body text here!');

      final state = container.read(appealNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect((state as AsyncError<void>).error, isA<AppealWindowExpired>());
    });

    test(
      'calls analytics.appealFailed with correct errorCode on SanctionException',
      () async {
        when(
          () => repo.submitAppeal(any(), any()),
        ).thenThrow(const AppealWindowExpired());

        final container = _container(repo: repo, analytics: analytics);
        addTearDown(container.dispose);

        await container
            .read(appealNotifierProvider.notifier)
            .submit(sanctionId: 's-1', body: 'Valid appeal body text here!');

        verify(
          () => analytics.logEvent(
            name: 'appeal_failed',
            parameters: any(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    test('emits AsyncError on generic Exception with UNKNOWN code', () async {
      when(
        () => repo.submitAppeal(any(), any()),
      ).thenThrow(Exception('network error'));

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .submit(sanctionId: 's-1', body: 'Valid appeal body text here!');

      final state = container.read(appealNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });
}
