import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_repository.dart';

/// SharedPreferences-backed onboarding completion persistence.
///
/// Stores a boolean flag under [_key]. Follows the same constructor-injection
/// pattern as `SharedPrefsConsentRepository`.
class SharedPrefsOnboardingRepo implements OnboardingRepository {
  SharedPrefsOnboardingRepo(this._prefs);

  static const _key = 'onboarding_complete';
  final SharedPreferences _prefs;

  @override
  Future<bool> isComplete() async {
    return _prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> complete() async {
    await _prefs.setBool(_key, true);
  }
}
