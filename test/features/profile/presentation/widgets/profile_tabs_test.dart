import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_tabs.dart';

void main() {
  group('ProfileTabs', () {
    testWidgets('renders two tabs with correct labels', (tester) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: Column(children: [ProfileTabs(controller: controller)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // .tr() returns the key path in tests.
      expect(find.text('profile.listings'), findsOneWidget);
      expect(find.text('profile.reviewsTab'), findsOneWidget);
    });

    testWidgets('renders exactly 2 Tab widgets', (tester) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: Column(children: [ProfileTabs(controller: controller)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('tab controller changes index on tap', (tester) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: Column(children: [ProfileTabs(controller: controller)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.index, equals(0));

      // Tap the second tab.
      await tester.tap(find.text('profile.reviewsTab'));
      await tester.pumpAndSettle();

      expect(controller.index, equals(1));
    });
  });
}
