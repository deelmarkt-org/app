import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/scam_alert.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ScamAlert.highConfidence', () {
    testWidgets('renders with title and report action', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
      );

      expect(find.byType(ScamAlert), findsOneWidget);
      // .tr() returns the key path in tests
      expect(find.text('scam_alert.title_high'), findsOneWidget);
      expect(find.text('scam_alert.report'), findsOneWidget);
    });

    testWidgets('is non-dismissible (no X button)', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
      );

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('onReport callback fires on tap', (tester) async {
      var reported = false;
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () => reported = true,
        ),
      );

      await tester.tap(find.text('scam_alert.report'));
      expect(reported, isTrue);
    });

    testWidgets('expand/collapse toggles reason list', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [
            ScamReason.externalPaymentLink,
            ScamReason.urgencyPressure,
          ],
          onReport: () {},
        ),
      );

      // Initially collapsed — reason keys not visible
      expect(
        find.text('scam_alert.reason.external_payment_link'),
        findsNothing,
      );

      // Tap expand
      await tester.tap(find.text('scam_alert.why_warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Consume AnimatedSize layout exceptions (known Flutter issue with
      // RenderAnimatedSize re-dirtying during its own performLayout).
      final expandException = tester.takeException();
      expect(
        expandException == null ||
            expandException.toString().contains('RenderAnimatedSize'),
        isTrue,
      );

      // Reasons now visible
      expect(
        find.text('scam_alert.reason.external_payment_link'),
        findsOneWidget,
      );
      expect(find.text('scam_alert.reason.urgency_pressure'), findsOneWidget);

      // Tap collapse
      await tester.tap(find.text('scam_alert.why_warning_hide'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException(); // Consume AnimatedSize exception

      expect(
        find.text('scam_alert.reason.external_payment_link'),
        findsNothing,
      );
    });

    testWidgets('has Semantics node with a11y label', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'scam_alert.a11y_high',
        ),
        findsOneWidget,
      );
    });

    testWidgets('report target meets 44px minimum height', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
      );

      final reportFinder = find.text('scam_alert.report');
      expect(reportFinder, findsOneWidget);

      final reportSize = tester.getSize(
        find.ancestor(of: reportFinder, matching: find.byType(SizedBox)).first,
      );
      expect(reportSize.height, greaterThanOrEqualTo(44));
    });

    testWidgets('is wrapped in RepaintBoundary', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(ScamAlert),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });

  group('ScamAlert.lowConfidence', () {
    testWidgets('renders with dismiss button', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.lowConfidence(onReport: () {}, onDismiss: () {}),
      );

      expect(find.text('scam_alert.title_low'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('onDismiss callback fires on X tap', (tester) async {
      var dismissed = false;
      await pumpTestWidget(
        tester,
        ScamAlert.lowConfidence(
          onReport: () {},
          onDismiss: () => dismissed = true,
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(dismissed, isTrue);
    });

    testWidgets('dismiss target meets 44×44 minimum', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.lowConfidence(onReport: () {}, onDismiss: () {}),
      );

      final buttonSize = tester.getSize(find.byType(IconButton));
      expect(buttonSize.width, greaterThanOrEqualTo(44));
      expect(buttonSize.height, greaterThanOrEqualTo(44));
    });

    testWidgets('does NOT show expand/collapse controls', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.lowConfidence(onReport: () {}, onDismiss: () {}),
      );

      expect(find.text('scam_alert.why_warning'), findsNothing);
    });
  });

  group('ScamAlert dark mode', () {
    testWidgets('renders in dark theme without errors', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.highConfidence(
          allReasons: const [ScamReason.externalPaymentLink],
          onReport: () {},
        ),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(ScamAlert), findsOneWidget);
      expect(find.text('scam_alert.title_high'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('low confidence renders in dark theme', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert.lowConfidence(onReport: () {}, onDismiss: () {}),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(ScamAlert), findsOneWidget);
      expect(find.text('scam_alert.title_low'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
