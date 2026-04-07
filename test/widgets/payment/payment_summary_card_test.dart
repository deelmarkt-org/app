import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/payment/payment_summary_card.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PaymentSummaryCard', () {
    testWidgets('displays item name and amounts', (tester) async {
      await pumpTestWidget(
        tester,
        PaymentSummaryCard(
          itemName: 'Vintage stoel',
          itemAmountCents: 4500,
          platformFeeCents: 113,
          shippingCostCents: 695,
          onPayPressed: () {},
        ),
      );

      expect(find.text('Vintage stoel'), findsOneWidget);
      // Euro formatting: €45,00
      expect(find.textContaining('45,00'), findsWidgets);
    });

    testWidgets('displays correct total', (tester) async {
      await pumpTestWidget(
        tester,
        PaymentSummaryCard(
          itemName: 'Test item',
          itemAmountCents: 1000,
          platformFeeCents: 50,
          shippingCostCents: 200,
          onPayPressed: () {},
        ),
      );

      // Total = 1000 + 50 + 200 = 1250 cents = €12,50
      expect(find.textContaining('12,50'), findsWidgets);
    });

    testWidgets('contains escrow trust banner', (tester) async {
      await pumpTestWidget(
        tester,
        PaymentSummaryCard(
          itemName: 'Item',
          itemAmountCents: 1000,
          platformFeeCents: 25,
          shippingCostCents: 500,
          onPayPressed: () {},
        ),
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('contains pay button', (tester) async {
      await pumpTestWidget(
        tester,
        PaymentSummaryCard(
          itemName: 'Item',
          itemAmountCents: 1000,
          platformFeeCents: 25,
          shippingCostCents: 500,
          onPayPressed: () {},
        ),
      );

      expect(find.byType(DeelButton), findsOneWidget);
    });

    testWidgets('pay button fires onPayPressed', (tester) async {
      var pressed = false;
      await pumpTestWidget(
        tester,
        PaymentSummaryCard(
          itemName: 'Item',
          itemAmountCents: 1000,
          platformFeeCents: 25,
          shippingCostCents: 500,
          onPayPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('loading state disables button', (tester) async {
      // Don't use pumpTestWidget — loading spinner never settles.
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentSummaryCard(
                itemName: 'Item',
                itemAmountCents: 1000,
                platformFeeCents: 25,
                shippingCostCents: 500,
                onPayPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('null onPayPressed disables button', (tester) async {
      await pumpTestWidget(
        tester,
        const PaymentSummaryCard(
          itemName: 'Item',
          itemAmountCents: 1000,
          platformFeeCents: 25,
          shippingCostCents: 500,
          onPayPressed: null,
        ),
      );

      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.onPressed, isNull);
    });
  });
}
