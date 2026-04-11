import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_stats_row.dart';

Widget buildRow(SellerStatsEntity stats) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: Scaffold(
      body: SizedBox(height: 200, child: SellerStatsRow(stats: stats)),
    ),
  );
}

void main() {
  group('SellerStatsRow', () {
    const stats = SellerStatsEntity(
      totalSalesCents: 12500,
      activeListingsCount: 4,
      unreadMessagesCount: 2,
    );

    testWidgets('renders total sales formatted as euro', (tester) async {
      await tester.pumpWidget(buildRow(stats));
      await tester.pump();

      expect(find.text(Formatters.euroFromCents(12500)), findsOneWidget);
    });

    testWidgets('renders active listings count', (tester) async {
      await tester.pumpWidget(buildRow(stats));
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('renders unread messages count', (tester) async {
      await tester.pumpWidget(buildRow(stats));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders without error when unread count is zero', (
      tester,
    ) async {
      const zeroStats = SellerStatsEntity(
        totalSalesCents: 0,
        activeListingsCount: 0,
        unreadMessagesCount: 0,
      );
      await tester.pumpWidget(buildRow(zeroStats));
      await tester.pump();

      expect(find.byType(SellerStatsRow), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('renders dark mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const Scaffold(
            body: SizedBox(height: 200, child: SellerStatsRow(stats: stats)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SellerStatsRow), findsOneWidget);
    });
  });
}
