import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_tokens.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelBadge accessibility', () {
    testWidgets('badge renders Semantics widget', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('tooltip wraps badge in ConstrainedBox for tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      // Find the ConstrainedBox with our specific minTapTarget constraints
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final tapTargetBox = constrainedBoxes.where(
        (cb) =>
            cb.constraints.minWidth >= DeelBadgeTokens.minTapTarget &&
            cb.constraints.minHeight >= DeelBadgeTokens.minTapTarget,
      );
      expect(tapTargetBox, isNotEmpty);
    });

    testWidgets('without tooltip, no Tooltip widget', (tester) async {
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

    testWidgets('badge row renders Semantics', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadgeRow(
            badges: [DeelBadgeType.emailVerified, DeelBadgeType.phoneVerified],
          ),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
