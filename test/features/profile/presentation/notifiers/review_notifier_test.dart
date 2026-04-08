import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';

/// Creates a [User] for testing.
User _testUser({String id = 'user-current'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  );
}

/// Creates a [ProviderContainer] with mock repositories, shared preferences,
/// and a simulated logged-in user.
Future<ProviderContainer> _createContainer({
  String userId = 'user-current',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      useMockDataProvider.overrideWithValue(true),
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(_testUser(id: userId)),
    ],
  );
}

/// Reads notifier state after async build completes.
Future<ReviewScreenState> _waitForState(
  ProviderContainer container,
  String txnId,
) async {
  container.listen(reviewNotifierProvider(txnId), (_, _) {});
  // Mock repos simulate 200-300ms delay; allow extra headroom under CI load
  await Future<void>.delayed(const Duration(milliseconds: 1000));
  final asyncVal = container.read(reviewNotifierProvider(txnId));
  return asyncVal.requireValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReviewNotifier', () {
    test('released transaction loads draft state', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-001');
      expect(state, isA<ReviewDraftState>());
      final draft = state as ReviewDraftState;
      expect(draft.rating, 0);
      expect(draft.body, isEmpty);
      expect(draft.idempotencyKey, isNotEmpty);
      expect(draft.role, isNotNull);
    });

    test('cancelled transaction returns ineligible', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-cancelled');
      expect(state, isA<ReviewIneligible>());
      expect(
        (state as ReviewIneligible).reason,
        'review.error.ineligible.cancelled',
      );
    });

    test('escrow-held transaction returns ineligible', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-pending');
      expect(state, isA<ReviewIneligible>());
      expect(
        (state as ReviewIneligible).reason,
        'review.error.ineligible.escrow_held',
      );
    });

    test('non-existent transaction returns ineligible', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-nonexistent');
      expect(state, isA<ReviewIneligible>());
      expect(
        (state as ReviewIneligible).reason,
        'review.error.ineligible.not_found',
      );
    });

    test('null user returns ineligible', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-001');
      expect(state, isA<ReviewIneligible>());
      expect(
        (state as ReviewIneligible).reason,
        'review.error.ineligible.auth',
      );
    });

    test('updateRating changes draft state', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-001');
      expect(state, isA<ReviewDraftState>());

      container
          .read(reviewNotifierProvider('txn-001').notifier)
          .updateRating(4);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated =
          container.read(reviewNotifierProvider('txn-001')).requireValue;
      expect(updated, isA<ReviewDraftState>());
      expect((updated as ReviewDraftState).rating, 4);
    });

    test('updateBody changes draft state', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'txn-001');

      container
          .read(reviewNotifierProvider('txn-001').notifier)
          .updateBody('Great seller!');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated =
          container.read(reviewNotifierProvider('txn-001')).requireValue;
      expect(updated, isA<ReviewDraftState>());
      expect((updated as ReviewDraftState).body, 'Great seller!');
    });

    test('hasUnsavedChanges returns true after body update', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'txn-001');

      final notifier = container.read(
        reviewNotifierProvider('txn-001').notifier,
      );
      expect(notifier.hasUnsavedChanges(), isFalse);

      notifier.updateBody('Some text');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.hasUnsavedChanges(), isTrue);
    });

    test('hasUnsavedChanges returns true after rating update', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'txn-001');

      final notifier = container.read(
        reviewNotifierProvider('txn-001').notifier,
      );
      // ignore: cascade_invocations
      notifier.updateRating(3);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.hasUnsavedChanges(), isTrue);
    });

    test('submit transitions to submitted state', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'txn-001');

      final notifier =
          container.read(reviewNotifierProvider('txn-001').notifier)
            ..updateRating(4)
            ..updateBody('Excellent transaction');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.submit();
      // Wait for mock delay
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final state =
          container.read(reviewNotifierProvider('txn-001')).requireValue;
      expect(state, isA<ReviewSubmitted>());
    });

    test('canSubmit is false when rating is 0', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-001');
      expect(state, isA<ReviewDraftState>());
      expect((state as ReviewDraftState).canSubmit, isFalse);
    });

    test('canSubmit is true when rating >= 1', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      await _waitForState(container, 'txn-001');

      container
          .read(reviewNotifierProvider('txn-001').notifier)
          .updateRating(3);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated =
          container.read(reviewNotifierProvider('txn-001')).requireValue
              as ReviewDraftState;
      expect(updated.canSubmit, isTrue);
    });

    test('txn-002 with existing review shows submitted/waiting', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-002');
      expect(state, isA<ReviewSubmitted>());
    });

    test('txn-003 with both reviews shows bothVisible', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final state = await _waitForState(container, 'txn-003');
      expect(state, isA<ReviewBothVisible>());
      final bothVisible = state as ReviewBothVisible;
      expect(bothVisible.myReview, isNotNull);
      expect(bothVisible.theirReview, isNotNull);
    });
  });

  group('ReviewErrorClass', () {
    test('all enum values exist', () {
      expect(ReviewErrorClass.values.length, 7);
      expect(ReviewErrorClass.values, contains(ReviewErrorClass.network));
      expect(ReviewErrorClass.values, contains(ReviewErrorClass.conflict));
      expect(ReviewErrorClass.values, contains(ReviewErrorClass.rateLimit));
    });
  });

  group('ReviewScreenState sealed hierarchy', () {
    test('all states are distinct types', () {
      const loading = ReviewLoading();
      const ineligible = ReviewIneligible(reason: 'test');
      const submitting = ReviewSubmitting();

      expect(loading, isA<ReviewScreenState>());
      expect(ineligible, isA<ReviewScreenState>());
      expect(submitting, isA<ReviewScreenState>());
      expect(loading, isNot(equals(ineligible)));
    });
  });
}
