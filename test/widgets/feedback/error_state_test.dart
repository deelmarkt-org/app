import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import 'feedback_test_helper.dart';

void main() {
  group('ErrorState standard', () {
    testWidgets('renders default error message', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: ErrorState(onRetry: () {})),
      );
      expect(find.text('error.generic'), findsOneWidget);
    });

    testWidgets('renders warning icon', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: ErrorState(onRetry: () {})),
      );
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders custom error message', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: ErrorState(onRetry: () {}, message: 'Custom error occurred'),
        ),
      );
      expect(find.text('Custom error occurred'), findsOneWidget);
    });

    testWidgets('retry button fires callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildFeedbackApp(child: ErrorState(onRetry: () => retried = true)),
      );
      await tester.tap(find.byType(DeelButton));
      expect(retried, isTrue);
    });

    testWidgets('uses DeelButton primary variant', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: ErrorState(onRetry: () {})),
      );
      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.variant, DeelButtonVariant.primary);
      expect(button.size, DeelButtonSize.medium);
    });

    testWidgets('has Semantics liveRegion on error text', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(child: ErrorState(onRetry: () {})),
      );
      expect(find.bySemanticsLabel('error.generic'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          theme: DeelmarktTheme.dark,
          child: ErrorState(onRetry: () {}),
        ),
      );
      expect(find.byType(ErrorState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ErrorState offline', () {
    testWidgets('shows offline banner', (tester) async {
      await tester.pumpWidget(
        buildBoundedFeedbackApp(
          child: ErrorState(onRetry: () {}, isOffline: true),
        ),
      );
      expect(find.text('error.offline'), findsOneWidget);
    });

    testWidgets('renders cached content below banner', (tester) async {
      await tester.pumpWidget(
        buildBoundedFeedbackApp(
          child: ErrorState(
            onRetry: () {},
            isOffline: true,
            cachedContent: const Center(child: Text('Cached listings here')),
          ),
        ),
      );
      expect(find.text('Cached listings here'), findsOneWidget);
      expect(find.text('error.offline'), findsOneWidget);
    });

    testWidgets('shows network error when no cached content', (tester) async {
      await tester.pumpWidget(
        buildBoundedFeedbackApp(
          child: ErrorState(onRetry: () {}, isOffline: true),
        ),
      );
      expect(find.text('error.network'), findsOneWidget);
    });

    testWidgets('retry button present in offline mode', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildBoundedFeedbackApp(
          child: ErrorState(onRetry: () => retried = true, isOffline: true),
        ),
      );
      await tester.tap(find.byType(DeelButton));
      expect(retried, isTrue);
    });
  });
}
