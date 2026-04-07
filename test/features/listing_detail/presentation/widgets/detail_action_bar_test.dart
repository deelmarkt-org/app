import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  Widget buildBar({
    int priceInCents = 4500,
    bool isOwnListing = false,
    VoidCallback? onMessage,
    VoidCallback? onBuy,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DetailActionBar(
              priceInCents: priceInCents,
              isOwnListing: isOwnListing,
              onMessage: onMessage,
              onBuy: onBuy,
              onEdit: onEdit,
              onDelete: onDelete,
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

    testWidgets('buyer variant renders message and buy buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar());
      await tester.pump();

      expect(find.text('listing_detail.messageButton'), findsOneWidget);
      expect(find.textContaining('listing_detail.buyButton'), findsOneWidget);
    });

    testWidgets('owner variant renders edit and delete buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar(isOwnListing: true));
      await tester.pump();

      expect(find.text('action.edit'), findsOneWidget);
      expect(find.text('action.delete'), findsOneWidget);
    });

    testWidgets('owner variant does not render message or buy buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar(isOwnListing: true));
      await tester.pump();

      expect(find.text('listing_detail.messageButton'), findsNothing);
      expect(find.textContaining('listing_detail.buyButton'), findsNothing);
    });

    testWidgets('buyer variant does not render edit or delete buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar());
      await tester.pump();

      expect(find.text('action.edit'), findsNothing);
      expect(find.text('action.delete'), findsNothing);
    });

    testWidgets('onMessage callback fires', (tester) async {
      var called = false;
      await tester.pumpWidget(buildBar(onMessage: () => called = true));
      await tester.pump();

      await tester.tap(find.text('listing_detail.messageButton'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onBuy callback fires', (tester) async {
      var called = false;
      await tester.pumpWidget(buildBar(onBuy: () => called = true));
      await tester.pump();

      await tester.tap(find.textContaining('listing_detail.buyButton'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onEdit callback fires on owner variant', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildBar(isOwnListing: true, onEdit: () => called = true),
      );
      await tester.pump();

      await tester.tap(find.text('action.edit'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onDelete callback fires on owner variant', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildBar(isOwnListing: true, onDelete: () => called = true),
      );
      await tester.pump();

      await tester.tap(find.text('action.delete'));
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
