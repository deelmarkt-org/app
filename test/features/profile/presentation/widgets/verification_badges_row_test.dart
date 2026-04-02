import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/verification_badges_row.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('VerificationBadgesRow', () {
    group('maps BadgeType to DeelBadgeType', () {
      testWidgets('emailVerified maps to visual badge', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.emailVerified]),
        );

        expect(find.byType(DeelBadgeRow), findsOneWidget);
      });

      testWidgets('phoneVerified maps to visual badge', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.phoneVerified]),
        );

        expect(find.byType(DeelBadgeRow), findsOneWidget);
      });

      testWidgets('idVerified maps to visual badge', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.idVerified]),
        );

        expect(find.byType(DeelBadgeRow), findsOneWidget);
      });

      testWidgets('trustedSeller maps to visual badge', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.trustedSeller]),
        );

        expect(find.byType(DeelBadgeRow), findsOneWidget);
      });
    });

    group('filters out non-visual types', () {
      testWidgets('fastResponder is filtered out', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.fastResponder]),
        );

        expect(find.byType(DeelBadgeRow), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets('newUser is filtered out', (tester) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(badges: [BadgeType.newUser]),
        );

        expect(find.byType(DeelBadgeRow), findsNothing);
      });

      testWidgets('only non-visual types results in empty widget', (
        tester,
      ) async {
        await pumpTestWidget(
          tester,
          const VerificationBadgesRow(
            badges: [BadgeType.fastResponder, BadgeType.newUser],
          ),
        );

        expect(find.byType(DeelBadgeRow), findsNothing);
      });
    });

    group('empty list', () {
      testWidgets('empty list shows nothing', (tester) async {
        await pumpTestWidget(tester, const VerificationBadgesRow(badges: []));

        expect(find.byType(DeelBadgeRow), findsNothing);
      });
    });

    testWidgets('mixed badges filters correctly', (tester) async {
      await pumpTestWidget(
        tester,
        const VerificationBadgesRow(
          badges: [
            BadgeType.emailVerified,
            BadgeType.fastResponder,
            BadgeType.phoneVerified,
            BadgeType.newUser,
          ],
        ),
      );

      expect(find.byType(DeelBadgeRow), findsOneWidget);
      final row = tester.widget<DeelBadgeRow>(find.byType(DeelBadgeRow));
      expect(row.badges.length, 2);
      expect(row.badges[0], DeelBadgeType.emailVerified);
      expect(row.badges[1], DeelBadgeType.phoneVerified);
    });
  });
}
