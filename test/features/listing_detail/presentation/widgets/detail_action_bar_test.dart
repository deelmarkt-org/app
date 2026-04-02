import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  Widget buildBar({
    int priceInCents = 4500,
    VoidCallback? onMessage,
    VoidCallback? onBuy,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DetailActionBar(
              priceInCents: priceInCents,
              onMessage: onMessage,
              onBuy: onBuy,
            ),
          ],
        ),
      ),
    );
  }

  group('DetailActionBar', () {
    testWidgets('renders two buttons', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pump();
      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('has elevation shadow', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.boxShadow, isNotNull);
    });
  });
}
