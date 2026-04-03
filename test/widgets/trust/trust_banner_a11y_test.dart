import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('TrustBanner accessibility', () {
    testWidgets('escrow variant has Semantics', (tester) async {
      await pumpTestWidget(tester, const TrustBanner.escrow());

      final semantics = find.descendant(
        of: find.byType(TrustBanner),
        matching: find.byType(Semantics),
      );
      expect(semantics, findsWidgets);
    });

    testWidgets('info variant has Semantics', (tester) async {
      await pumpTestWidget(
        tester,
        const TrustBanner.info(
          title: 'Info Title',
          description: 'Info description',
        ),
      );

      final semantics = find.descendant(
        of: find.byType(TrustBanner),
        matching: find.byType(Semantics),
      );
      expect(semantics, findsWidgets);
    });

    testWidgets('is never dismissible (no close button)', (tester) async {
      await pumpTestWidget(tester, const TrustBanner.escrow());
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
