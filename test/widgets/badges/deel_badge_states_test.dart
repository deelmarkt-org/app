import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelBadge verified/unverified states', () {
    testWidgets('verified badge uses type-specific colour', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final lightTheme = DeelBadgeThemeData.light();
      expect(icon.color, lightTheme.verified);
    });

    testWidgets('unverified badge uses neutral colour', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(
            type: DeelBadgeType.emailVerified,
            isVerified: false,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final lightTheme = DeelBadgeThemeData.light();
      expect(icon.color, lightTheme.unverified);
    });

    testWidgets('unverified badge uses neutral background', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(
            type: DeelBadgeType.emailVerified,
            isVerified: false,
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final lightTheme = DeelBadgeThemeData.light();
      expect(decoration.color, lightTheme.unverifiedBackground);
    });

    testWidgets('escrow badge uses escrow colour', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.escrowProtected),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final lightTheme = DeelBadgeThemeData.light();
      expect(icon.color, lightTheme.escrow);
    });

    testWidgets('topSeller badge uses gold colour', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelBadge(type: DeelBadgeType.topSeller)),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final lightTheme = DeelBadgeThemeData.light();
      expect(icon.color, lightTheme.gold);
    });
  });

  group('DeelBadge tooltip', () {
    testWidgets('tooltip shown by default', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('tooltip hidden when showTooltip is false', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(
            type: DeelBadgeType.emailVerified,
            showTooltip: false,
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('DeelBadgeType.fromBadgeType', () {
    test('maps emailVerified', () {
      expect(
        DeelBadgeType.fromBadgeType(BadgeType.emailVerified),
        DeelBadgeType.emailVerified,
      );
    });

    test('maps phoneVerified', () {
      expect(
        DeelBadgeType.fromBadgeType(BadgeType.phoneVerified),
        DeelBadgeType.phoneVerified,
      );
    });

    test('maps idVerified', () {
      expect(
        DeelBadgeType.fromBadgeType(BadgeType.idVerified),
        DeelBadgeType.idVerified,
      );
    });

    test('returns null for fastResponder', () {
      expect(DeelBadgeType.fromBadgeType(BadgeType.fastResponder), isNull);
    });

    test('returns null for newUser', () {
      expect(DeelBadgeType.fromBadgeType(BadgeType.newUser), isNull);
    });
  });
}
