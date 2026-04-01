import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/kyc_banner.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('KycBanner', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, KycBanner(onVerify: () {}));
      expect(find.byType(KycBanner), findsOneWidget);
    });

    testWidgets('fires onVerify callback', (tester) async {
      var tapped = false;
      await pumpTestWidget(tester, KycBanner(onVerify: () => tapped = true));

      await tester.tap(find.byType(TextButton));
      expect(tapped, isTrue);
    });

    testWidgets('has shield warning icon', (tester) async {
      await pumpTestWidget(tester, KycBanner(onVerify: () {}));
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
