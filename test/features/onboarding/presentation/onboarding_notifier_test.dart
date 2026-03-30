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
    test('initial state has currentPage 0 and isComplete false', () {
      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 0);
      expect(state.isComplete, false);
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

    test('completeOnboarding sets isComplete and persists', () async {
      await container
          .read(onboardingNotifierProvider.notifier)
          .completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isComplete, true);

      // Verify persistence
      expect(prefs.getBool('onboarding_complete'), true);
    });

    test('shouldShowOnboarding returns true when not complete', () async {
      final result =
          await container
              .read(onboardingNotifierProvider.notifier)
              .shouldShowOnboarding();
      expect(result, true);
    });

    test('shouldShowOnboarding returns false after completion', () async {
      await container
          .read(onboardingNotifierProvider.notifier)
          .completeOnboarding();

      final result =
          await container
              .read(onboardingNotifierProvider.notifier)
              .shouldShowOnboarding();
      expect(result, false);
    });

    test('setPage preserves isComplete state', () async {
      await container
          .read(onboardingNotifierProvider.notifier)
          .completeOnboarding();
      container.read(onboardingNotifierProvider.notifier).setPage(2);

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentPage, 2);
      expect(state.isComplete, true);
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
