import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/onboarding/domain/onboarding_repository.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/get_started_page.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_feature_card.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/welcome_page.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Mock repository that throws on [complete] to test error handling.
class _FailingOnboardingRepo implements OnboardingRepository {
  @override
  Future<bool> isComplete() async => false;

  @override
  Future<void> complete() async => throw Exception('SharedPreferences failed');
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('full flow: swipe, back nav, page dots, and error SnackBar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await EasyLocalization.ensureInitialized();

      // --- Phase 1: Normal flow with failing repo ---
      // (tests error handling + navigation in one session)
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: AppLocales.supportedLocales,
          fallbackLocale: AppLocales.fallbackLocale,
          path: AppLocales.path,
          child: Builder(
            builder:
                (context) => ProviderScope(
                  overrides: [
                    sharedPreferencesProvider.overrideWithValue(prefs),
                    onboardingRepositoryProvider.overrideWithValue(
                      _FailingOnboardingRepo(),
                    ),
                  ],
                  child: MaterialApp(
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    theme: DeelmarktTheme.light,
                    home: const OnboardingScreen(),
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // --- Page 1: Welcome ---
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Primary DeelButton (Next) visible
      expect(
        find.byWidgetPredicate(
          (w) => w is DeelButton && w.variant == DeelButtonVariant.primary,
        ),
        findsOneWidget,
      );

      // 3 page indicator dots
      expect(
        find.byWidgetPredicate((w) => w is AnimatedContainer),
        findsNWidgets(3),
      );

      // --- Swipe to Page 2: Trust ---
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
      expect(find.byType(TrustFeatureCard), findsNWidgets(3));

      // --- Back nav: PopScope sends back to Page 1 ---
      final dynamic widgetsBinding = tester.binding;
      // ignore: avoid_dynamic_calls
      await widgetsBinding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);

      // --- Swipe to Page 3: Get Started ---
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
      expect(find.byType(GetStartedPage), findsOneWidget);
      expect(find.byType(DeelButton), findsAtLeast(2));

      // --- Error handling: tap Create Account with failing repo ---
      final createBtn = find.byWidgetPredicate(
        (w) => w is DeelButton && w.variant == DeelButtonVariant.primary,
      );
      await tester.ensureVisible(createBtn);
      await tester.pumpAndSettle();
      await tester.tap(createBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // SnackBar should appear with error message
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
