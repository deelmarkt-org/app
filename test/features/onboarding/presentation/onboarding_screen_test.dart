import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/get_started_page.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_feature_card.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/welcome_page.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders welcome page with Next button, page dots, '
        'and supports swipe navigation through all 3 pages', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await EasyLocalization.ensureInitialized();

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

      // Trust page shows 3 feature cards
      expect(find.byType(TrustFeatureCard), findsNWidgets(3));

      // --- Swipe to Page 3: Get Started ---
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      // GetStartedPage visible with 2 DeelButtons (create + login)
      expect(find.byType(GetStartedPage), findsOneWidget);
      expect(find.byType(DeelButton), findsAtLeast(2));
    });
  });
}
