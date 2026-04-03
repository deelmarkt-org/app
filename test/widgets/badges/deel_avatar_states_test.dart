import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/widgets/badges/deel_avatar.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelAvatar initials', () {
    testWidgets('"Mahmut Kaya" shows "MK"', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Mahmut Kaya')),
      );

      expect(find.text('MK'), findsOneWidget);
    });

    testWidgets('"Sophie" shows "S"', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Sophie')),
      );

      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('empty name shows "?"', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: '')),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('three-word name uses first and last', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Jan van Dijk')),
      );

      expect(find.text('JD'), findsOneWidget);
    });
  });

  group('DeelAvatar placeholder state (no imageUrl)', () {
    testWidgets('shows initials when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Test User')),
      );

      expect(find.text('TU'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('DeelAvatar edit overlay', () {
    testWidgets('shows camera icon when showEditOverlay is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelAvatar(displayName: 'Test', showEditOverlay: true),
        ),
      );

      expect(find.byIcon(PhosphorIconsBold.camera), findsOneWidget);
    });

    testWidgets('hides camera icon by default', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Test')),
      );

      expect(find.byIcon(PhosphorIconsBold.camera), findsNothing);
    });

    testWidgets('fires onEditTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildBadgeApp(
          child: DeelAvatar(
            displayName: 'Test',
            showEditOverlay: true,
            onEditTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });
  });

  group('DeelAvatar badge overlay', () {
    testWidgets('shows badge when badgeType provided', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelAvatar(
            displayName: 'Test',
            badgeType: DeelBadgeType.emailVerified,
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsOneWidget);
    });

    testWidgets('no badge when badgeType is null', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Test')),
      );

      expect(find.byType(DeelBadge), findsNothing);
    });
  });
}
