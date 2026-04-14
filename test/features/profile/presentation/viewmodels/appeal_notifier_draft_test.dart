/// Tests for [AppealNotifier] — draft persistence (P-53 Phase G).
///
/// Covers: saveDraft, loadDraft, clearDraft idempotency and key format.
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
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/appeal_notifier.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

/// Builds a container with all required overrides.
ProviderContainer _container({
  required SanctionRepository repo,
  required FirebaseAnalytics analytics,
}) {
  return ProviderContainer(
    overrides: [
      sanctionRepositoryProvider.overrideWithValue(repo),
      firebaseAnalyticsProvider.overrideWithValue(analytics),
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
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AppealNotifier — draft persistence', () {
    test('saveDraft stores value under appeal_draft_{id} key', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .saveDraft(sanctionId: 'sanction-abc', body: 'my draft text');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appeal_draft_sanction-abc'), 'my draft text');
    });

    test('loadDraft returns null when no draft saved', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final draft = await container
          .read(appealNotifierProvider.notifier)
          .loadDraft(sanctionId: 'no-draft-here');
      expect(draft, isNull);
    });

    test('loadDraft returns saved draft', () async {
      SharedPreferences.setMockInitialValues({
        'appeal_draft_s-2': 'saved draft',
      });

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      final draft = await container
          .read(appealNotifierProvider.notifier)
          .loadDraft(sanctionId: 's-2');
      expect(draft, 'saved draft');
    });

    test('clearDraft removes the key', () async {
      SharedPreferences.setMockInitialValues({'appeal_draft_s-3': 'to clear'});

      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .clearDraft(sanctionId: 's-3');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appeal_draft_s-3'), isNull);
    });

    test('saveDraft key format is appeal_draft_<sanctionId>', () async {
      final container = _container(repo: repo, analytics: analytics);
      addTearDown(container.dispose);

      await container
          .read(appealNotifierProvider.notifier)
          .saveDraft(sanctionId: 'xyz-789', body: 'draft body');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appeal_draft_xyz-789'), 'draft body');
    });

    test(
      'saveDraft is idempotent — overwriting with same value is safe',
      () async {
        final container = _container(repo: repo, analytics: analytics);
        addTearDown(container.dispose);

        final notifier = container.read(appealNotifierProvider.notifier);
        await notifier.saveDraft(sanctionId: 's-4', body: 'same');
        await notifier.saveDraft(sanctionId: 's-4', body: 'same');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('appeal_draft_s-4'), 'same');
      },
    );
  });
}
