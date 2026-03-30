import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/welcome_page.dart';
import 'package:deelmarkt/widgets/settings/language_switch.dart';

void main() {
  group('WelcomePage', () {
    Future<void> pumpWelcomePage(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: AppLocales.supportedLocales,
          fallbackLocale: AppLocales.fallbackLocale,
          path: AppLocales.path,
          child: Builder(
            builder:
                (context) => MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: DeelmarktTheme.light,
                  home: const Scaffold(body: WelcomePage()),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders logo text and LanguageSwitch', (tester) async {
      await pumpWelcomePage(tester);

      expect(find.textContaining('DeelMarkt'), findsAtLeast(1));
      expect(find.byType(LanguageSwitch), findsOneWidget);
    });
  });
}
