import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';

void main() {
  group('SharedPreferences provider', () {
    test('initSharedPreferences initialises the instance', () async {
      SharedPreferences.setMockInitialValues({});
      await initSharedPreferences();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs, isA<SharedPreferences>());
    });

    test('initSharedPreferences can be called multiple times safely', () async {
      SharedPreferences.setMockInitialValues({});
      await initSharedPreferences();
      await initSharedPreferences();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(sharedPreferencesProvider),
        isA<SharedPreferences>(),
      );
    });

    test('provider returns same instance on multiple reads', () async {
      SharedPreferences.setMockInitialValues({'test_key': true});
      await initSharedPreferences();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(sharedPreferencesProvider);
      final second = container.read(sharedPreferencesProvider);
      expect(identical(first, second), isTrue);
    });

    test('provider override works in tests', () async {
      SharedPreferences.setMockInitialValues({'mock': true});
      final mockPrefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
      );
      addTearDown(container.dispose);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool('mock'), isTrue);
    });
  });
}
