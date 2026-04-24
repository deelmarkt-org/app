import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';

void main() {
  group('Breakpoints constants', () {
    test('compact is 600', () {
      expect(Breakpoints.compact, 600);
    });

    test('medium is 840', () {
      expect(Breakpoints.medium, 840);
    });

    test('expanded is 1200', () {
      expect(Breakpoints.expanded, 1200);
    });

    test('contentMaxWidth is 500', () {
      expect(Breakpoints.contentMaxWidth, 500);
    });

    test('authCardMaxWidth is 480', () {
      expect(Breakpoints.authCardMaxWidth, 480);
    });

    test('formMaxWidth is 600', () {
      expect(Breakpoints.formMaxWidth, 600);
    });
  });

  group('Breakpoints helpers', () {
    testWidgets('isCompact returns true for narrow screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isCompact(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isCompact returns false for wide screens', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isCompact(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('isMedium returns true between compact and medium', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isMedium(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isMedium returns false for expanded screens', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isMedium(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('isExpanded returns true for wide screens', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isExpanded(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isExpanded returns false for compact screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isExpanded(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('isLarge returns true at 1400px', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isLarge(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isLarge returns false at 900px (expanded but not large)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = Breakpoints.isLarge(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    test('gridColumnsForContainerWidth returns 2/3/4/5 per threshold', () {
      expect(Breakpoints.gridColumnsForContainerWidth(400), 2);
      expect(Breakpoints.gridColumnsForContainerWidth(599.9), 2);
      expect(Breakpoints.gridColumnsForContainerWidth(600), 3);
      expect(Breakpoints.gridColumnsForContainerWidth(700), 3);
      expect(Breakpoints.gridColumnsForContainerWidth(839.9), 3);
      expect(Breakpoints.gridColumnsForContainerWidth(840), 4);
      expect(Breakpoints.gridColumnsForContainerWidth(900), 4);
      expect(Breakpoints.gridColumnsForContainerWidth(1199.9), 4);
      expect(Breakpoints.gridColumnsForContainerWidth(1200), 5);
      expect(Breakpoints.gridColumnsForContainerWidth(1400), 5);
      expect(Breakpoints.gridColumnsForContainerWidth(1800), 5);
    });

    testWidgets(
      'gridColumnsForWidth delegates to gridColumnsForContainerWidth via MediaQuery',
      (tester) async {
        tester.view.physicalSize = const Size(959, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late int contextResult;
        late int directResult;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                contextResult = Breakpoints.gridColumnsForWidth(context);
                directResult = Breakpoints.gridColumnsForContainerWidth(
                  MediaQuery.sizeOf(context).width,
                );
                return const SizedBox();
              },
            ),
          ),
        );
        expect(contextResult, directResult);
        expect(contextResult, 4); // 959 < 1200
      },
    );

    testWidgets('gridColumnsForWidth returns 2/3/4/5 per breakpoint', (
      tester,
    ) async {
      Future<int> columnsAt(double width) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        late int result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = Breakpoints.gridColumnsForWidth(context);
                return const SizedBox();
              },
            ),
          ),
        );
        return result;
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      expect(await columnsAt(400), 2);
      expect(await columnsAt(700), 3);
      expect(await columnsAt(900), 4);
      expect(await columnsAt(1400), 5);
    });
  });
}
