import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import '../data/shared_prefs_onboarding_repo.dart';
import '../domain/onboarding_repository.dart';

part 'onboarding_notifier.g.dart';

/// Onboarding state — immutable via Dart record type.
///
/// [currentPage]: which PageView page is visible (0-indexed).
/// [isComplete]: whether the user has finished onboarding.
typedef OnboardingState = ({int currentPage, bool isComplete});

/// Provides the [OnboardingRepository] — reads SharedPreferences provider.
@riverpod
OnboardingRepository onboardingRepository(OnboardingRepositoryRef ref) {
  return SharedPrefsOnboardingRepo(ref.watch(sharedPreferencesProvider));
}

/// Manages onboarding page state and completion persistence.
///
/// This is the first class-based Notifier in the codebase. It uses the
/// `@riverpod` annotation with `class ... extends _$...` syntax from
/// `riverpod_annotation ^2.6.1`. See Riverpod docs:
/// https://riverpod.dev/docs/concepts/about_code_generation#notifiers
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => (currentPage: 0, isComplete: false);

  /// Updates the current page index. Called from PageController listener.
  void setPage(int page) {
    state = (currentPage: page, isComplete: state.isComplete);
  }

  /// Marks onboarding as complete in SharedPreferences and updates state.
  Future<void> completeOnboarding() async {
    await ref.read(onboardingRepositoryProvider).complete();
    state = (currentPage: state.currentPage, isComplete: true);
  }

  /// Returns `true` if onboarding should be shown (not yet completed).
  Future<bool> shouldShowOnboarding() async {
    final complete = await ref.read(onboardingRepositoryProvider).isComplete();
    return !complete;
  }
}
