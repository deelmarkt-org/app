import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/kyc_faq_expandable.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('KycFaqExpandable', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const KycFaqExpandable());
      expect(find.byType(KycFaqExpandable), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await pumpTestWidget(tester, const KycFaqExpandable());
      expect(find.text('kyc.whatIsIdin'), findsOneWidget);
    });

    testWidgets('renders as ExpansionTile', (tester) async {
      await pumpTestWidget(tester, const KycFaqExpandable());
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('shows explanation text after tapping', (tester) async {
      await pumpTestWidget(tester, const KycFaqExpandable());

      await tester.tap(find.text('kyc.whatIsIdin'));
      await tester.pumpAndSettle();

      expect(find.text('kyc.idinExplanation'), findsOneWidget);
    });
  });
}
