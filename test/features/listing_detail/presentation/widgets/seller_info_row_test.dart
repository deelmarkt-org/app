import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/seller_info_row.dart';

UserEntity _seller({
  double? averageRating,
  int reviewCount = 0,
  int? responseTimeMinutes,
}) {
  return UserEntity(
    id: 'seller-1',
    displayName: 'Test Seller',
    kycLevel: KycLevel.level0,
    createdAt: DateTime(2025),
    averageRating: averageRating,
    reviewCount: reviewCount,
    responseTimeMinutes: responseTimeMinutes,
  );
}

void main() {
  Widget buildRow({required UserEntity seller}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(body: SellerInfoRow(seller: seller)),
    );
  }

  group('SellerInfoRow', () {
    testWidgets('renders rating when present', (tester) async {
      await tester.pumpWidget(
        buildRow(seller: _seller(averageRating: 4.5, reviewCount: 10)),
      );
      await tester.pump();

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text(' (10)'), findsOneWidget);
    });

    testWidgets('hides review count when zero', (tester) async {
      await tester.pumpWidget(buildRow(seller: _seller(averageRating: 3.0)));
      await tester.pump();

      expect(find.text('3.0'), findsOneWidget);
      expect(find.text(' (0)'), findsNothing);
    });

    testWidgets('renders empty when no rating and no response time', (
      tester,
    ) async {
      await tester.pumpWidget(buildRow(seller: _seller()));
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders response time in minutes', (tester) async {
      await tester.pumpWidget(
        buildRow(seller: _seller(responseTimeMinutes: 30)),
      );
      await tester.pump();

      expect(find.byType(SellerInfoRow), findsOneWidget);
    });

    testWidgets('renders response time in hours', (tester) async {
      await tester.pumpWidget(
        buildRow(seller: _seller(responseTimeMinutes: 120)),
      );
      await tester.pump();

      expect(find.byType(SellerInfoRow), findsOneWidget);
    });

    testWidgets('renders separator when both rating and response time', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRow(
          seller: _seller(
            averageRating: 4.0,
            reviewCount: 5,
            responseTimeMinutes: 45,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(' · '), findsOneWidget);
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: Scaffold(
            body: SellerInfoRow(
              seller: _seller(averageRating: 4.0, responseTimeMinutes: 60),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SellerInfoRow), findsOneWidget);
    });
  });
}
