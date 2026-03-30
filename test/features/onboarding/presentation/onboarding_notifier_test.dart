import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_notifier.dart';

void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  group('OnboardingNotifier', () {
    test('initial state has currentPage 0', () {
      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 0);
    });

    test('setPage updates currentPage', () {
      container.read(onboardingNotifierProvider.notifier).setPage(1);
      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 1);
    });

    test('setPage to page 2 updates correctly', () {
      container.read(onboardingNotifierProvider.notifier).setPage(2);
      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 2);
    });

    test('completeOnboarding persists to SharedPreferences', () async {
      await container
          .read(onboardingNotifierProvider.notifier)
          .completeOnboarding();

      // Verify persistence
      expect(prefs.getBool('onboarding_complete'), true);
    });

    test(
      'completeOnboarding invalidates isOnboardingCompleteProvider',
      () async {
        // Before completion
        final before = await container.read(
          isOnboardingCompleteProvider.future,
        );
        expect(before, false);

        await container
            .read(onboardingNotifierProvider.notifier)
            .completeOnboarding();

        // After completion — provider was invalidated and re-reads from prefs
        final after = await container.read(isOnboardingCompleteProvider.future);
        expect(after, true);
      },
    );

    test('setPage preserves page state after multiple updates', () {
      container.read(onboardingNotifierProvider.notifier).setPage(1);
      container.read(onboardingNotifierProvider.notifier).setPage(2);

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 2);
    });
  });

  group('isOnboardingCompleteProvider', () {
    test('returns false when not complete', () async {
      final result = await container.read(isOnboardingCompleteProvider.future);
      expect(result, false);
    });

    test('returns true after completion', () async {
      await prefs.setBool('onboarding_complete', true);
      // Need a fresh container to pick up the new value
      container.dispose();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final result = await container.read(isOnboardingCompleteProvider.future);
      expect(result, true);
    });
  });

  group('onboardingRepositoryProvider', () {
    test('provides a working repository', () async {
      final repo = container.read(onboardingRepositoryProvider);
      expect(await repo.isComplete(), false);

      await repo.complete();
      expect(await repo.isComplete(), true);
    });
  });
}
