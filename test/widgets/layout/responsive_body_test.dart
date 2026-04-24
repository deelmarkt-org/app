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

  group('ResponsiveBody.wide', () {
    testWidgets('defaults to 1200px cap', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(1600, 900)),
          child: MaterialApp(
            home: Scaffold(body: ResponsiveBody.wide(child: Text('Wide'))),
          ),
        ),
      );
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 1200);
    });

    testWidgets('wide constructor honours custom maxWidth', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(1600, 900)),
          child: MaterialApp(
            home: Scaffold(
              body: ResponsiveBody.wide(maxWidth: 1000, child: Text('Wide')),
            ),
          ),
        ),
      );
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 1000);
    });

    testWidgets('wide constructor omits horizontal padding by default '
        '(callers own margins)', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(1600, 900)),
          child: MaterialApp(
            home: Scaffold(body: ResponsiveBody.wide(child: Text('Wide'))),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(ResponsiveBody),
          matching: find.byType(Padding),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'wide constructor adds padding when addHorizontalPadding: true',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(1600, 900)),
            child: MaterialApp(
              home: Scaffold(
                body: ResponsiveBody.wide(
                  addHorizontalPadding: true,
                  child: Text('Wide'),
                ),
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(ResponsiveBody),
            matching: find.byType(Padding),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('ResponsiveBody addHorizontalPadding flag', () {
    testWidgets(
      'default ResponsiveBody(…) keeps horizontal padding (regression pin)',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(375, 800)),
            child: MaterialApp(
              home: Scaffold(body: ResponsiveBody(child: Text('Form'))),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(ResponsiveBody),
            matching: find.byType(Padding),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ResponsiveBody(…) drops padding when addHorizontalPadding: false',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(375, 800)),
            child: MaterialApp(
              home: Scaffold(
                body: ResponsiveBody(
                  addHorizontalPadding: false,
                  child: Text('Form'),
                ),
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(ResponsiveBody),
            matching: find.byType(Padding),
          ),
          findsNothing,
        );
      },
    );
  });
}
