import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/welcome_page.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders WelcomePage, PageView and Scaffold on initial load', (
      tester,
    ) async {
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
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeast(1));
    });
  });
}
