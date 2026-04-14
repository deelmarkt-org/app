import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';

part 'appeal_notifier.g.dart';

String _draftKey(String sanctionId) => 'appeal_draft_$sanctionId';

/// Manages appeal submission lifecycle and draft persistence for a sanction.
///
/// States:
/// - [AsyncData(null)] — idle / success
/// - [AsyncLoading] — submission in progress
/// - [AsyncError] — submission failed (surface to user via screen)
///
/// Draft storage uses [SharedPreferences] directly (no abstraction layer
/// needed for a single local key-value pair).
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: docs/screens/SCREEN-MAP.md (P-53 Appeal Screen)
@riverpod
class AppealNotifier extends _$AppealNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Submits (or revises) the appeal for [sanctionId].
  ///
  /// Client-side guard: [body] must be 10–1000 characters.
  /// On success: invalidates [activeSanctionProvider], clears the draft.
  /// On failure: surfaces [AsyncError] with the original exception.
  Future<void> submit({
    required String sanctionId,
    required String body,
  }) async {
    if (body.trim().length < 10 || body.length > 1000) {
      throw ArgumentError('invalid appeal body length');
    }

    state = const AsyncLoading();

    final repo = ref.read(sanctionRepositoryProvider);
    try {
      await repo.submitAppeal(sanctionId, body);

      // Invalidate so SuspensionGateScreen re-evaluates after appeal.
      ref.invalidate(activeSanctionProvider);

      await clearDraft(sanctionId: sanctionId);

      ref
          .read(sanctionAnalyticsProvider)
          .appealSubmitted(sanctionId: sanctionId, bodyLength: body.length);

      state = const AsyncData(null);
    } on SanctionException catch (e, stack) {
      ref
          .read(sanctionAnalyticsProvider)
          .appealFailed(sanctionId: sanctionId, errorCode: e.code);
      state = AsyncError(e, stack);
    } on Exception catch (e, stack) {
      ref
          .read(sanctionAnalyticsProvider)
          .appealFailed(sanctionId: sanctionId, errorCode: 'UNKNOWN');
      state = AsyncError(e, stack);
    }
  }

  /// Persists the draft [body] for [sanctionId] to [SharedPreferences].
  ///
  /// Idempotent — calling repeatedly with the same value is safe.
  Future<void> saveDraft({
    required String sanctionId,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey(sanctionId), body);
  }

  /// Loads the saved draft for [sanctionId], or `null` if none exists.
  Future<String?> loadDraft({required String sanctionId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftKey(sanctionId));
  }

  /// Removes the draft for [sanctionId] from [SharedPreferences].
  Future<void> clearDraft({required String sanctionId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(sanctionId));
  }
}
