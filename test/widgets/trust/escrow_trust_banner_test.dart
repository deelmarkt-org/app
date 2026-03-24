import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EscrowTrustBanner', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const EscrowTrustBanner());
      expect(find.byType(EscrowTrustBanner), findsOneWidget);
    });

    testWidgets('contains shield icon', (tester) async {
      await pumpTestWidget(tester, const EscrowTrustBanner());
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('shows more info button when callback provided', (
      tester,
    ) async {
      var tapped = false;
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
      await pumpTestWidget(tester, const EscrowTrustBanner());
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      await pumpTestWidget(tester, const EscrowTrustBanner());
      // Verify Semantics exists in the widget tree
      final semantics = find.descendant(
        of: find.byType(EscrowTrustBanner),
        matching: find.byType(Semantics),
      );
      expect(semantics, findsWidgets);
    });
  });
}
