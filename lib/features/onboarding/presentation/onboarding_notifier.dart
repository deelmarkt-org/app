import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import '../data/shared_prefs_onboarding_repo.dart';
import '../domain/onboarding_repository.dart';

part 'onboarding_notifier.g.dart';

/// Onboarding state — immutable via Dart record type.
///
/// [currentPage]: which PageView page is visible (0-indexed).
typedef OnboardingState = ({int currentPage});

/// Provides the [OnboardingRepository] — reads SharedPreferences provider.
@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  return SharedPrefsOnboardingRepo(ref.watch(sharedPreferencesProvider));
}

/// Whether onboarding has been completed — used by auth guard to skip
/// the onboarding route for returning users. Loaded once at startup.
@Riverpod(keepAlive: true)
Future<bool> isOnboardingComplete(Ref ref) async {
  try {
    final repo = ref.watch(onboardingRepositoryProvider);
    return repo.isComplete();
  } catch (e) {
    debugPrint('Onboarding completion check failed: $e');
    return false; // fail-open: show onboarding as safe default
  }
}

/// Manages onboarding page state and completion persistence.
///
/// Uses `@Riverpod(keepAlive: true)` to prevent state loss if a system
/// dialog triggers during the flow (e.g. permission prompt).
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => (currentPage: 0);

  /// Updates the current page index. Called from PageController listener.
  void setPage(int page) {
    state = (currentPage: page);
  }

  /// Marks onboarding as complete in SharedPreferences and invalidates
  /// the [isOnboardingCompleteProvider] so the auth guard picks up the change.
  Future<void> completeOnboarding() async {
    try {
      await ref.read(onboardingRepositoryProvider).complete();
      ref.invalidate(isOnboardingCompleteProvider);
    } catch (e) {
      debugPrint('Failed to complete onboarding: $e');
    }
  }
}
