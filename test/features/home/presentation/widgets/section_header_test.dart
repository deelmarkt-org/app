import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';

void main() {
  Widget buildHeader({
    String title = 'Nearby',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  group('SectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildHeader(title: 'Test Title'));
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders action label when provided', (tester) async {
      await tester.pumpWidget(
        buildHeader(actionLabel: 'View all', onAction: () {}),
      );
      expect(find.text('View all'), findsOneWidget);
    });

    testWidgets('does not render action when label is null', (tester) async {
      await tester.pumpWidget(buildHeader());
      expect(find.text('View all'), findsNothing);
    });

    testWidgets('action tap calls onAction', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildHeader(actionLabel: 'View all', onAction: () => tapped = true),
      );

      await tester.tap(find.text('View all'));
      expect(tapped, isTrue);
    });

    testWidgets('action uses InkWell for focus support', (tester) async {
      await tester.pumpWidget(
        buildHeader(actionLabel: 'View all', onAction: () {}),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
