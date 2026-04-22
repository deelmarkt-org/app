import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_activity_usecase.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:deelmarkt/features/admin/presentation/admin_dashboard_notifier.dart';
import 'package:deelmarkt/features/admin/presentation/admin_providers.dart';

class _MockAdminRepo extends Mock implements AdminRepository {}

AdminStatsEntity _stats({int openDisputes = 1}) => AdminStatsEntity(
  openDisputes: openDisputes,
  dsaNoticesWithin24h: 0,
  activeListings: 10,
  escrowAmountCents: 0,
  flaggedListings: 0,
  reportedUsers: 0,
  approvedCount: 0,
);

final _activity = [
  ActivityItemEntity(
    id: 'a1',
    type: ActivityItemType.listingRemoved,
    params: const {'listingId': 'l-1'},
    timestamp: DateTime(2026, 4, 20),
  ),
];

ProviderContainer _makeContainer({required AdminRepository repo}) {
  return ProviderContainer(
    overrides: [
      getAdminStatsUseCaseProvider.overrideWithValue(
        GetAdminStatsUseCase(repo),
      ),
      getAdminActivityUseCaseProvider.overrideWithValue(
        GetAdminActivityUseCase(repo),
      ),
    ],
  );
}

void main() {
  group('AdminDashboardState', () {
    const stats = AdminStatsEntity(
      openDisputes: 5,
      dsaNoticesWithin24h: 2,
      activeListings: 100,
      escrowAmountCents: 50000,
      flaggedListings: 3,
      reportedUsers: 1,
      approvedCount: 90,
    );

    const emptyStats = AdminStatsEntity(
      openDisputes: 0,
      dsaNoticesWithin24h: 0,
      activeListings: 0,
      escrowAmountCents: 0,
      flaggedListings: 0,
      reportedUsers: 0,
      approvedCount: 0,
    );

    test('isEmpty is false when any moderation counter is non-zero', () {
      const state = AdminDashboardState(stats: stats, activity: []);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty is true when all moderation counters are zero', () {
      const state = AdminDashboardState(stats: emptyStats, activity: []);
      expect(state.isEmpty, isTrue);
    });

    test('equality based on stats and activity', () {
      const state1 = AdminDashboardState(stats: stats, activity: []);
      const state2 = AdminDashboardState(stats: stats, activity: []);
      expect(state1, equals(state2));
    });

    test('inequality when stats differ', () {
      const state1 = AdminDashboardState(stats: stats, activity: []);
      const state2 = AdminDashboardState(stats: emptyStats, activity: []);
      expect(state1, isNot(equals(state2)));
    });
  });

  group('AdminDashboardNotifier', () {
    late _MockAdminRepo repo;

    setUp(() {
      repo = _MockAdminRepo();
    });

    test('build(): returns state with stats + activity on success', () async {
      when(() => repo.getStats()).thenAnswer((_) async => _stats());
      when(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _activity);

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      final state = await container.read(adminDashboardNotifierProvider.future);

      expect(state.stats, _stats());
      expect(state.activity, _activity);
      verify(() => repo.getStats()).called(1);
      verify(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).called(1);
    });

    test('build(): propagates error as AsyncError', () async {
      when(() => repo.getStats()).thenThrow(StateError('stats down'));
      when(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _activity);

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(adminDashboardNotifierProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test('refresh(): replaces state with fresh data', () async {
      // Initial build returns 1 open dispute; refresh returns 7.
      var callCount = 0;
      when(() => repo.getStats()).thenAnswer((_) async {
        callCount++;
        return _stats(openDisputes: callCount == 1 ? 1 : 7);
      });
      when(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _activity);

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      final first = await container.read(adminDashboardNotifierProvider.future);
      expect(first.stats.openDisputes, 1);

      await container.read(adminDashboardNotifierProvider.notifier).refresh();
      final second = await container.read(
        adminDashboardNotifierProvider.future,
      );
      expect(second.stats.openDisputes, 7);
      verify(() => repo.getStats()).called(2);
    });

    test('refresh(): emits loading state transiently', () async {
      when(() => repo.getStats()).thenAnswer((_) async => _stats());
      when(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _activity);

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(adminDashboardNotifierProvider.future);

      final states = <AsyncValue<AdminDashboardState>>[];
      container.listen<AsyncValue<AdminDashboardState>>(
        adminDashboardNotifierProvider,
        (_, next) => states.add(next),
      );

      final refreshFuture =
          container.read(adminDashboardNotifierProvider.notifier).refresh();

      // Between setting AsyncValue.loading and awaiting guard, the
      // listener must have seen a loading frame.
      await refreshFuture;
      expect(
        states.any((s) => s.isLoading),
        isTrue,
        reason: 'refresh must expose a loading frame for PullToRefresh UI',
      );
      expect(states.last.hasValue, isTrue);
    });

    test('refresh(): surfaces repository errors as AsyncError', () async {
      var callCount = 0;
      when(() => repo.getStats()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return _stats();
        throw StateError('refresh failure');
      });
      when(
        () => repo.getRecentActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _activity);

      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(adminDashboardNotifierProvider.future);
      await container.read(adminDashboardNotifierProvider.notifier).refresh();

      final state = container.read(adminDashboardNotifierProvider);
      expect(state.hasError, isTrue);
      // `(a, b).wait` wraps thrown errors in a ParallelWaitError. The
      // assertion below is message-based so it survives either wrapping
      // or future unwrapping without coupling to the implementation.
      expect(state.error.toString(), contains('refresh failure'));
    });

    test(
      'parallel fetch: stats and activity are awaited concurrently, not sequentially',
      () async {
        // Deterministic concurrency assertion: each mock signals "started"
        // immediately and blocks on a shared release Completer. If the
        // notifier awaited them sequentially, only `statsStarted` would
        // fire before we release — `activityStarted` would still be pending.
        // We assert BOTH have started before we release either side.
        final statsStarted = Completer<void>();
        final activityStarted = Completer<void>();
        final release = Completer<void>();

        when(() => repo.getStats()).thenAnswer((_) async {
          statsStarted.complete();
          await release.future;
          return _stats();
        });
        when(
          () => repo.getRecentActivity(limit: any(named: 'limit')),
        ).thenAnswer((_) async {
          activityStarted.complete();
          await release.future;
          return _activity;
        });

        final container = _makeContainer(repo: repo);
        addTearDown(container.dispose);

        final buildFuture = container.read(
          adminDashboardNotifierProvider.future,
        );

        // Both calls must be in flight before either returns.
        await Future.wait([statsStarted.future, activityStarted.future]);
        release.complete();
        await buildFuture;
      },
    );

    test('dispose during in-flight fetch: no unhandled error leaks', () async {
      when(() => repo.getStats()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _stats();
      });
      when(() => repo.getRecentActivity(limit: any(named: 'limit'))).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _activity;
        },
      );

      final container = _makeContainer(repo: repo);
      // Kick off the fetch without awaiting.
      final future = container.read(adminDashboardNotifierProvider.future);
      container.dispose();
      // The in-flight future should resolve without throwing into the
      // zone (Riverpod 3 guarantees cancellation doesn't leak errors).
      await expectLater(future, completes);
    });
  });
}
