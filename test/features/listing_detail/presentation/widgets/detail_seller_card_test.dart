import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_seller_card.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

final _testSeller = UserEntity(
  id: 'seller-1',
  displayName: 'Jan de Vries',
  kycLevel: KycLevel.level2,
  createdAt: DateTime(2025),
  averageRating: 4.7,
  reviewCount: 42,
  responseTimeMinutes: 90,
  badges: const [BadgeType.emailVerified, BadgeType.phoneVerified],
);

void main() {
  Widget buildCard({UserEntity? seller, VoidCallback? onViewProfile}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: DetailSellerCard(
          seller: seller ?? _testSeller,
          onViewProfile: onViewProfile ?? () {},
        ),
      ),
    );
  }

  group('DetailSellerCard', () {
    testWidgets('renders seller name', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text('Jan de Vries'), findsOneWidget);
    });

    testWidgets('renders rating', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets('renders review count', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text(' (42)'), findsOneWidget);
    });

    testWidgets('calls onViewProfile when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onViewProfile: () => tapped = true));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows initials when no avatar', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('shows no rating row when null', (tester) async {
      final noRating = UserEntity(
        id: 'seller-2',
        displayName: 'Test',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2025),
      );
      await tester.pumpWidget(buildCard(seller: noRating));
      await tester.pump();
      expect(find.text('4.7'), findsNothing);
    });
  });
}
