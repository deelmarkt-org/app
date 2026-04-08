import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/presentation/providers/review_draft_provider.dart';

Future<ProviderContainer> _createContainer([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('ReviewDraft', () {
    test('fromJson parses valid data', () {
      final draft = ReviewDraft.fromJson({
        'rating': 4.0,
        'body': 'Great!',
        'idempotencyKey': 'key-123',
        'lastModifiedAt': DateTime.now().toIso8601String(),
      });

      expect(draft.rating, 4.0);
      expect(draft.body, 'Great!');
      expect(draft.idempotencyKey, 'key-123');
    });

    test('fromJson handles missing fields with defaults', () {
      final draft = ReviewDraft.fromJson({});

      expect(draft.rating, 0);
      expect(draft.body, isEmpty);
      expect(draft.idempotencyKey, isEmpty);
    });

    test('toJson round-trips correctly', () {
      final original = ReviewDraft(
        rating: 3.0,
        body: 'Nice',
        idempotencyKey: 'key-456',
        lastModifiedAt: DateTime(2026, 4, 5),
      );

      final roundTripped = ReviewDraft.fromJson(original.toJson());
      expect(roundTripped.rating, original.rating);
      expect(roundTripped.body, original.body);
      expect(roundTripped.idempotencyKey, original.idempotencyKey);
    });

    test('isExpired returns true for old drafts', () {
      final oldDraft = ReviewDraft(
        rating: 3.0,
        body: 'Old',
        idempotencyKey: 'old-key',
        lastModifiedAt: DateTime.now().subtract(const Duration(days: 31)),
      );

      expect(oldDraft.isExpired, isTrue);
    });

    test('isExpired returns false for recent drafts', () {
      final recentDraft = ReviewDraft(
        rating: 3.0,
        body: 'Recent',
        idempotencyKey: 'recent-key',
        lastModifiedAt: DateTime.now(),
      );

      expect(recentDraft.isExpired, isFalse);
    });

    test('copyWith updates fields and refreshes timestamp', () {
      final original = ReviewDraft(
        rating: 2.0,
        body: 'Original',
        idempotencyKey: 'key-789',
        lastModifiedAt: DateTime(2026, 3, 15),
      );

      final updated = original.copyWith(rating: 5.0, body: 'Updated');
      expect(updated.rating, 5.0);
      expect(updated.body, 'Updated');
      expect(updated.idempotencyKey, original.idempotencyKey);
      expect(updated.lastModifiedAt.isAfter(original.lastModifiedAt), isTrue);
    });
  });

  group('ReviewDraftNotifier', () {
    test('returns null when no draft exists', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final draft = container.read(reviewDraftNotifierProvider('txn-new'));
      expect(draft, isNull);
    });

    test('save persists and returns draft', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        reviewDraftNotifierProvider('txn-save').notifier,
      );
      final draft = ReviewDraft(
        rating: 4.0,
        body: 'Saved!',
        idempotencyKey: 'save-key',
        lastModifiedAt: DateTime.now(),
      );
      notifier.save(draft);

      final loaded = container.read(reviewDraftNotifierProvider('txn-save'));
      expect(loaded, isNotNull);
      expect(loaded!.rating, 4.0);
      expect(loaded.body, 'Saved!');
    });

    test('clear removes draft', () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        reviewDraftNotifierProvider('txn-clear').notifier,
      );
      // ignore: cascade_invocations
      notifier.save(
        ReviewDraft(
          rating: 3.0,
          body: 'To clear',
          idempotencyKey: 'clear-key',
          lastModifiedAt: DateTime.now(),
        ),
      );

      // ignore: cascade_invocations
      notifier.clear();

      final loaded = container.read(reviewDraftNotifierProvider('txn-clear'));
      expect(loaded, isNull);
    });
  });
}
