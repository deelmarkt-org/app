import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/theme_mode_notifier.dart';

/// Builds a [ProviderContainer] with [SharedPreferences] pre-seeded.
Future<ProviderContainer> makeContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  await initSharedPreferences();
  return ProviderContainer();
}

void main() {
  group('ThemeModeNotifier', () {
    test('defaults to ThemeMode.system on first launch', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
    });

    test('restores ThemeMode.light from SharedPreferences', () async {
      final container = await makeContainer(
        initialValues: {'theme_mode': 'light'},
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
    });

    test('restores ThemeMode.dark from SharedPreferences', () async {
      final container = await makeContainer(
        initialValues: {'theme_mode': 'dark'},
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    });

    test('setThemeMode updates state immediately', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);

      container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    });

    test('setThemeMode persists to SharedPreferences', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);

      container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.light);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('unknown stored value falls back to ThemeMode.system', () async {
      final container = await makeContainer(
        initialValues: {'theme_mode': 'invalid_value'},
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
    });
  });
}
