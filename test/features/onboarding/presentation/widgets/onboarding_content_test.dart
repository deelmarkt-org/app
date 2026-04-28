import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/onboarding_trust_badges.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/page_dot_indicator.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  group('OnboardingContent', () {
    Future<void> pumpSubject(
      WidgetTester tester, {
      required int currentPage,
      required bool isExpanded,
      required PageController controller,
      VoidCallback? onSkip,
      VoidCallback? onNext,
    }) async {
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
                  // Bound the vertical extent so the inner
                  // `Expanded(child: PageView)` has a finite height.
                  home: Scaffold(
                    body: SizedBox(
                      height: 800,
                      width: 600,
                      child: OnboardingContent(
                        currentPage: currentPage,
                        pageCount: 3,
                        pageController: controller,
                        isExpanded: isExpanded,
                        onSkip: onSkip ?? () {},
                        onNext: onNext ?? () {},
                        onCreateAccount: () {},
                        onLogin: () {},
                      ),
                    ),
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('compact layout omits the header skip button', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);

      await pumpSubject(
        tester,
        currentPage: 0,
        isExpanded: false,
        controller: controller,
      );

      // The header row only renders in expanded mode; it contains a ghost
      // DeelButton for the "Skip" action.
      final ghostButtons = find.byWidgetPredicate(
        (w) => w is DeelButton && w.variant == DeelButtonVariant.ghost,
      );
      expect(ghostButtons, findsNothing);
      expect(find.byType(OnboardingTrustBadges), findsOneWidget);
      expect(find.byType(PageDotIndicator), findsOneWidget);
    });

    testWidgets('Next button hides on the final page', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);

      await pumpSubject(
        tester,
        currentPage: 2, // last page (pageCount = 3 → index 0..2)
        isExpanded: false,
        controller: controller,
      );

      // The "Next" primary DeelButton lives directly inside
      // OnboardingContent's column. GetStartedPage on page 3 also
      // renders DeelButtons, but the PageController hasn't animated
      // there yet — only WelcomePage (page 0) is materialised in the
      // PageView at this point.
      final primaryAtRoot = find.descendant(
        of: find.byType(OnboardingContent),
        matching: find.byWidgetPredicate(
          (w) => w is DeelButton && w.variant != DeelButtonVariant.ghost,
        ),
      );
      // PageView lazily builds children — only the page at currentPage
      // is materialised. So the only DeelButtons we expect are on the
      // active page (none on the welcome page, but trust pages may have
      // their own). The key invariant: no "Next" button labeled with
      // `onboarding.next` is at the column root.
      expect(primaryAtRoot, findsNothing);
    });
  });
}
