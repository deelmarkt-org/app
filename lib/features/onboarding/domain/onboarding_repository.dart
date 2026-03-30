/// Onboarding completion persistence interface.
///
/// MVP: [SharedPrefsOnboardingRepo]. Checks whether the user has seen the
/// onboarding flow; if so, the auth guard skips `/onboarding`.
///
/// Pure Dart — no Flutter imports.
abstract class OnboardingRepository {
  /// Returns `true` if the user has completed onboarding.
  Future<bool> isComplete();

  /// Marks onboarding as complete. Subsequent calls to [isComplete] return `true`.
  Future<void> complete();
}
