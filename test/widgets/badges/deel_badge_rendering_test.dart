import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_tokens.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelBadge rendering', () {
    for (final type in DeelBadgeType.values) {
      testWidgets('renders ${type.name} badge with icon', (tester) async {
        await tester.pumpWidget(buildBadgeApp(child: DeelBadge(type: type)));

        final config = resolveConfig(type);
        expect(find.byIcon(config.icon), findsOneWidget);
      });
    }

    testWidgets('medium size renders 28px container', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.shape, BoxShape.circle);
      expect(container.constraints?.maxWidth, DeelBadgeTokens.containerMedium);
    });

    testWidgets('small size renders 24px container', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadge(
            type: DeelBadgeType.emailVerified,
            size: DeelBadgeSize.small,
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, DeelBadgeTokens.containerSmall);
    });

    testWidgets('dark mode uses dark theme colours', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          theme: DeelmarktTheme.dark,
          child: const DeelBadge(type: DeelBadgeType.emailVerified),
        ),
      );

      expect(find.byType(DeelBadge), findsOneWidget);
    });
  });

  group('DeelBadgeRow rendering', () {
    testWidgets('renders all badges when count <= maxVisible', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadgeRow(
            badges: [DeelBadgeType.emailVerified, DeelBadgeType.phoneVerified],
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('enforces max-3 constraint with overflow indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadgeRow(
            badges: [
              DeelBadgeType.emailVerified,
              DeelBadgeType.phoneVerified,
              DeelBadgeType.idinVerified,
              DeelBadgeType.idVerified,
              DeelBadgeType.topSeller,
            ],
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('empty badges list renders nothing', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelBadgeRow(badges: [])),
      );

      expect(find.byType(DeelBadge), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('custom maxVisible works', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelBadgeRow(
            badges: [
              DeelBadgeType.emailVerified,
              DeelBadgeType.phoneVerified,
              DeelBadgeType.idinVerified,
            ],
            maxVisible: 2,
          ),
        ),
      );

      expect(find.byType(DeelBadge), findsNWidgets(2));
      expect(find.text('+1'), findsOneWidget);
    });
  });
}
