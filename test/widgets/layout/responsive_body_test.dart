import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

Widget buildResponsiveApp({
  double width = 375,
  double height = 812,
  double maxWidth = 600,
}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: ResponsiveBody(maxWidth: maxWidth, child: const Text('Content')),
      ),
    ),
  );
}

void main() {
  group('ResponsiveBody compact layout', () {
    testWidgets('applies mobile margin at 375px', (tester) async {
      await tester.pumpWidget(buildResponsiveApp());
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(Padding).first,
        ),
      );
      final insets = padding.padding as EdgeInsets;
      expect(insets.left, Spacing.screenMarginMobile);
      expect(insets.right, Spacing.screenMarginMobile);
    });
  });

  group('ResponsiveBody medium layout', () {
    testWidgets('applies tablet margin at 700px', (tester) async {
      await tester.pumpWidget(buildResponsiveApp(width: 700));
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(Padding).first,
        ),
      );
      final insets = padding.padding as EdgeInsets;
      expect(insets.left, Spacing.screenMarginTablet);
    });
  });

  group('ResponsiveBody expanded layout', () {
    testWidgets('constrains to 600px maxWidth at 1000px', (tester) async {
      await tester.pumpWidget(buildResponsiveApp(width: 1000));
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 600);
    });

    testWidgets('custom maxWidth is respected', (tester) async {
      await tester.pumpWidget(buildResponsiveApp(width: 1000, maxWidth: 400));
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 400);
    });
  });

  group('ResponsiveBody general', () {
    testWidgets('child widget is rendered', (tester) async {
      await tester.pumpWidget(buildResponsiveApp());
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('content is centered', (tester) async {
      await tester.pumpWidget(buildResponsiveApp());
      expect(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });
  });
}
