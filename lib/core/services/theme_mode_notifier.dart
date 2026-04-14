import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';

part 'theme_mode_notifier.g.dart';

/// Persists and exposes the user's preferred [ThemeMode].
///
/// Reads from / writes to [SharedPreferences] via [sharedPreferencesProvider]
/// (initialised synchronously in `main()` before `runApp`).
/// Falls back to [ThemeMode.system] on first launch.
///
/// Consumed by [DeelMarktApp] to drive `MaterialApp.themeMode`.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return _fromString(prefs.getString(_key));
  }

  /// Persists [mode] and updates state immediately (no async gap in UI).
  void setThemeMode(ThemeMode mode) {
    ref.read(sharedPreferencesProvider).setString(_key, _toString(mode));
    state = mode;
  }

  static ThemeMode _fromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system, // explicit — mirrors _toString output
    _ => ThemeMode.system, // null / unknown / first launch
  };

  static String _toString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
