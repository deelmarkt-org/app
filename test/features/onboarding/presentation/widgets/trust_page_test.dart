import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_feature_card.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_page.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('TrustPage', () {
    testWidgets('renders trust title', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.text('onboarding.safe_buying'), findsOneWidget);
    });

    testWidgets('renders trust subtitle', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.text('onboarding.safe_buying_subtitle'), findsOneWidget);
    });

    testWidgets('renders 3 feature cards', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.byType(TrustFeatureCard), findsNWidgets(3));
    });

    testWidgets('renders escrow feature card', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.text('onboarding.escrow_title'), findsOneWidget);
      expect(find.text('onboarding.escrow_subtitle'), findsOneWidget);
    });

    testWidgets('renders verified sellers feature card', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.text('onboarding.verified_title'), findsOneWidget);
    });

    testWidgets('renders returns feature card', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(find.text('onboarding.returns_title'), findsOneWidget);
    });

    testWidgets('has trust shield Semantics label', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      expect(
        find.bySemanticsLabel('onboarding.trust_icon_label'),
        findsOneWidget,
      );
    });

    testWidgets('feature cards have Semantics labels', (tester) async {
      await pumpTestWidget(tester, const TrustPage());

      // Each TrustFeatureCard wraps in Semantics(label: '$title — $subtitle').
      // pumpTestWidget doesn't init EasyLocalization, so .tr() returns keys.
      // bySemanticsLabel uses RegExp — escape the em dash.
      expect(
        find.bySemanticsLabel(RegExp(r'onboarding\.escrow_title')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'onboarding\.verified_title')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'onboarding\.returns_title')),
        findsOneWidget,
      );
    });

    group('light mode trust colours', () {
      testWidgets('shield icon uses trustVerified green', (tester) async {
        await pumpTestWidget(tester, const TrustPage());

        // Top shield + verified sellers card both use trustVerified.
        final iconFinder = find.byWidgetPredicate(
          (w) => w is Icon && w.color == DeelmarktColors.trustVerified,
        );
        expect(iconFinder, findsNWidgets(2));
      });

      testWidgets('escrow card uses trustEscrow blue', (tester) async {
        await pumpTestWidget(tester, const TrustPage());

        final cards = tester.widgetList<TrustFeatureCard>(
          find.byType(TrustFeatureCard),
        );
        expect(cards.first.iconColor, DeelmarktColors.trustEscrow);
      });

      testWidgets('verified card uses trustVerified green', (tester) async {
        await pumpTestWidget(tester, const TrustPage());

        final cards =
            tester
                .widgetList<TrustFeatureCard>(find.byType(TrustFeatureCard))
                .toList();
        expect(cards[1].iconColor, DeelmarktColors.trustVerified);
      });
    });

    group('dark mode trust colours', () {
      testWidgets('shield icon uses dark trustVerified', (tester) async {
        await pumpTestWidget(
          tester,
          const TrustPage(),
          theme: DeelmarktTheme.dark,
        );

        final iconFinder = find.byWidgetPredicate(
          (w) => w is Icon && w.color == DeelmarktColors.darkTrustVerified,
        );
        expect(iconFinder, findsNWidgets(2));
      });

      testWidgets('escrow card uses dark trustEscrow', (tester) async {
        await pumpTestWidget(
          tester,
          const TrustPage(),
          theme: DeelmarktTheme.dark,
        );

        final cards = tester.widgetList<TrustFeatureCard>(
          find.byType(TrustFeatureCard),
        );
        expect(cards.first.iconColor, DeelmarktColors.darkTrustEscrow);
      });

      testWidgets('verified card uses dark trustVerified', (tester) async {
        await pumpTestWidget(
          tester,
          const TrustPage(),
          theme: DeelmarktTheme.dark,
        );

        final cards =
            tester
                .widgetList<TrustFeatureCard>(find.byType(TrustFeatureCard))
                .toList();
        expect(cards[1].iconColor, DeelmarktColors.darkTrustVerified);
      });
    });
  });
}
