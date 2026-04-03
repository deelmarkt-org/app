import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/kyc_trust_footer.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('KycTrustFooter', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const KycTrustFooter());
      expect(find.byType(KycTrustFooter), findsOneWidget);
    });

    testWidgets('shows trust footer text', (tester) async {
      await pumpTestWidget(tester, const KycTrustFooter());
      expect(find.text('kyc.trustFooter'), findsOneWidget);
    });

    testWidgets('has shield icon', (tester) async {
      await pumpTestWidget(tester, const KycTrustFooter());
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('uses Row layout for horizontal arrangement', (tester) async {
      await pumpTestWidget(tester, const KycTrustFooter());
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
