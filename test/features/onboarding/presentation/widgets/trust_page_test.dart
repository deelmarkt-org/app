import 'package:flutter_test/flutter_test.dart';

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
  });
}
