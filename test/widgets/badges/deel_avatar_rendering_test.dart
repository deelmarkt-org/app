import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar_tokens.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelAvatar rendering', () {
    testWidgets('small renders 32px', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelAvatar(
            displayName: 'Test User',
            size: DeelAvatarSize.small,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, DeelAvatarTokens.sizeSmall);
      expect(sizedBox.height, DeelAvatarTokens.sizeSmall);
    });

    testWidgets('medium renders 48px (default)', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Test User')),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, DeelAvatarTokens.sizeMedium);
    });

    testWidgets('large renders 80px', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          child: const DeelAvatar(
            displayName: 'Test User',
            size: DeelAvatarSize.large,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, DeelAvatarTokens.sizeLarge);
    });

    testWidgets('dark mode renders without errors', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(
          theme: DeelmarktTheme.dark,
          child: const DeelAvatar(displayName: 'Dark Test'),
        ),
      );

      expect(find.byType(DeelAvatar), findsOneWidget);
    });
  });
}
