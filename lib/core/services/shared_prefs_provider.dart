import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_prefs_provider.g.dart';

/// Module-private singleton set by [initSharedPreferences].
/// Follows the same pattern as [initUnleash] in `unleash_service.dart`.
SharedPreferences? _instance;

/// Initialise SharedPreferences in `main()` before `runApp`.
///
/// Must be called before any provider reads [sharedPreferencesProvider].
/// Added to `Future.wait` alongside Supabase, Firebase, and Unleash init.
Future<void> initSharedPreferences() async {
  _instance = await SharedPreferences.getInstance();
}

/// App-wide [SharedPreferences] instance — keepAlive since it's a singleton.
///
/// Throws [StateError] if [initSharedPreferences] was not called.
/// Used by: onboarding (P-14), consent (future), settings (future).
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  if (_instance == null) {
    throw StateError(
      'initSharedPreferences() must be called in main() before runApp()',
    );
  }
  return _instance!;
}
