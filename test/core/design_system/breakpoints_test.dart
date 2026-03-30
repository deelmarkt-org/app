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
  });
}
