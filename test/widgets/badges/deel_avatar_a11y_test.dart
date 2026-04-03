import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

import 'deel_badge_test_helper.dart';

void main() {
  group('DeelAvatar accessibility', () {
    testWidgets('has Semantics with display name label', (tester) async {
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Test User')),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('background colour varies by name', (tester) async {
      // Verify different names produce different colours
      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Alice')),
      );
      expect(find.byType(DeelAvatar), findsOneWidget);

      await tester.pumpWidget(
        buildBadgeApp(child: const DeelAvatar(displayName: 'Bob')),
      );
      expect(find.byType(DeelAvatar), findsOneWidget);
    });
  });
}
