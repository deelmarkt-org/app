import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';

void main() {
  group('SearchFavouritesMixin', () {
    test('_inFlight guard prevents duplicate concurrent toggles', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      )..listen(searchNotifierProvider, (_, _) {});
      addTearDown(container.dispose);
      await container.read(searchNotifierProvider.future);

      await container.read(searchNotifierProvider.notifier).search('e');
      final before = container.read(searchNotifierProvider).requireValue;
      expect(before.listings, isNotEmpty);

      final id = before.listings.first.id;
      final originalFav = before.listings.first.isFavourited;

      // Fire two concurrent toggles — only one should go through.
      // Both are awaited; the second call is a no-op due to the _inFlight guard.
      await Future.wait([
        container.read(searchNotifierProvider.notifier).toggleFavourite(id),
        container.read(searchNotifierProvider.notifier).toggleFavourite(id),
      ]);

      final after = container.read(searchNotifierProvider).requireValue;
      final toggled = after.listings.firstWhere((l) => l.id == id);
      // Exactly one toggle applied — state is the opposite of the original.
      expect(
        toggled.isFavourited,
        !originalFav,
        reason: 'Guard should prevent double-toggle cancelling itself out',
      );
    });
  });
}
