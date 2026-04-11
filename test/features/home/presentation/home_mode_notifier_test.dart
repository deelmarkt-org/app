import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';

void main() {
  group('HomeModeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      )..listen(homeModeNotifierProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('initial state is buyer', () {
      final mode = container.read(homeModeNotifierProvider);
      expect(mode, HomeMode.buyer);
    });

    test('toggle switches from buyer to seller', () {
      container.read(homeModeNotifierProvider.notifier).toggle();

      final mode = container.read(homeModeNotifierProvider);
      expect(mode, HomeMode.seller);
    });

    test('toggle switches from seller back to buyer', () {
      container.read(homeModeNotifierProvider.notifier)
        ..toggle() // buyer -> seller
        ..toggle(); // seller -> buyer

      final mode = container.read(homeModeNotifierProvider);
      expect(mode, HomeMode.buyer);
    });

    test('setMode sets specific mode', () {
      container
          .read(homeModeNotifierProvider.notifier)
          .setMode(HomeMode.seller);

      final mode = container.read(homeModeNotifierProvider);
      expect(mode, HomeMode.seller);
    });

    test('setMode is no-op when already in target mode', () {
      container.read(homeModeNotifierProvider.notifier).setMode(HomeMode.buyer);

      final mode = container.read(homeModeNotifierProvider);
      expect(mode, HomeMode.buyer);
    });

    test('persists mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      )..listen(homeModeNotifierProvider, (_, _) {});
      addTearDown(c.dispose);

      c.read(homeModeNotifierProvider.notifier).toggle();

      // Wait for async setMode to complete.
      await Future<void>.delayed(Duration.zero);

      expect(prefs.getString('home_mode'), 'seller');
    });
  });
}
