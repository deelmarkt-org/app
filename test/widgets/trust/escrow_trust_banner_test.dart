import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: deprecated_member_use_from_same_package
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EscrowTrustBanner (backward compatibility)', () {
    testWidgets('renders without errors', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      await pumpTestWidget(tester, const EscrowTrustBanner());
      // ignore: deprecated_member_use_from_same_package
      expect(find.byType(EscrowTrustBanner), findsOneWidget);
    });

    testWidgets('delegates to TrustBanner.escrow', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      await pumpTestWidget(tester, const EscrowTrustBanner());
      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('shows more info button when callback provided', (
      tester,
    ) async {
      var tapped = false;
      // ignore: deprecated_member_use_from_same_package
      await pumpTestWidget(
        tester,
        EscrowTrustBanner(onMoreInfo: () => tapped = true),
      );

      final buttons = find.byType(TextButton);
      expect(buttons, findsOneWidget);
      await tester.tap(buttons);
      expect(tapped, isTrue);
    });

    testWidgets('hides more info button when no callback', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      await pumpTestWidget(tester, const EscrowTrustBanner());
      expect(find.byType(TextButton), findsNothing);
    });
  });
}
