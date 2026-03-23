import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

import 'feedback_test_helper.dart';

void main() {
  group('SkeletonLoader', () {
    testWidgets('renders Shimmer with child', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Shimmer is enabled by default', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      expect(shimmer.enabled, isTrue);
    });

    testWidgets('enabled: false disables Shimmer', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(
            enabled: false,
            child: SizedBox(width: 100, height: 20),
          ),
        ),
      );
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      expect(shimmer.enabled, isFalse);
    });

    testWidgets('disableAnimations stops Shimmer', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          disableAnimations: true,
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      expect(shimmer.enabled, isFalse);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          theme: DeelmarktTheme.dark,
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      expect(find.bySemanticsLabel('a11y.loading'), findsOneWidget);
    });

    testWidgets('shimmer period is 1500ms', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(child: SizedBox(width: 100, height: 20)),
        ),
      );
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      expect(shimmer.period, const Duration(milliseconds: 1500));
    });
  });

  group('SkeletonLine', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: const SkeletonLoader(child: SkeletonLine())),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SkeletonLine),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.height, 16);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SkeletonLoader(
            child: SkeletonLine(width: 120, height: 24),
          ),
        ),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SkeletonLine),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 120);
      expect(box.height, 24);
    });
  });

  group('SkeletonCircle', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: const SkeletonLoader(child: SkeletonCircle())),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SkeletonCircle),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 48);
      expect(box.height, 48);
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: const SkeletonLoader(child: SkeletonBox())),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SkeletonBox),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.height, 120);
    });
  });

  group('SkeletonListingCard', () {
    testWidgets('has exactly one Shimmer widget', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: const SkeletonListingCard()),
      );
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('contains expected shape types', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: const SkeletonListingCard()),
      );
      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.byType(SkeletonLine), findsNWidgets(3));
      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: const SizedBox(width: 320, child: SkeletonListingCard()),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
