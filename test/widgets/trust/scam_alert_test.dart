import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/trust/scam_alert.dart';
import 'package:deelmarkt/widgets/trust/scam_alert_reason.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ScamAlert — high confidence', () {
    testWidgets('renders error-surface background and title key', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () {},
        ),
      );
      expect(find.textContaining('scam_alert.titleHigh'), findsOneWidget);
      expect(find.textContaining('scam_alert.subtitleLow'), findsNothing);
    });

    testWidgets('is non-dismissible (assert fires when onDismiss set)', (
      tester,
    ) async {
      expect(
        () => ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.phoneNumberRequest],
          onDismiss: () {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('onReport callback fires on button tap', (tester) async {
      var reported = false;
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () => reported = true,
        ),
      );
      await tester.tap(find.textContaining('scam_alert.report'));
      expect(reported, isTrue);
    });

    testWidgets('no dismiss button is rendered', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.other],
          onReport: () {},
        ),
      );
      // The inline "Negeren" text button should not appear.
      expect(find.textContaining('scam_alert.dismiss'), findsNothing);
    });

    testWidgets('asserts onReport is required for high confidence', (
      tester,
    ) async {
      expect(
        () => ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          // intentionally no onReport
        ),
        throwsAssertionError,
      );
    });
  });

  group('ScamAlert — low confidence', () {
    testWidgets('renders warning-surface title + subtitle', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.suspiciousPricing],
        ),
      );
      expect(find.textContaining('scam_alert.titleLow'), findsOneWidget);
      expect(find.textContaining('scam_alert.subtitleLow'), findsOneWidget);
    });

    testWidgets('dismiss button fires onDismiss when provided', (tester) async {
      var dismissed = false;
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onDismiss: () => dismissed = true,
        ),
      );
      // Dismiss icon-button has a11y label "scam_alert.dismiss"
      await tester.tap(find.bySemanticsLabel('scam_alert.dismiss').first);
      expect(dismissed, isTrue);
    });

    testWidgets('hides inline dismiss button when onDismiss is null', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.externalPaymentLink],
        ),
      );
      // No dismiss semantics, no inline "Negeren" text either.
      expect(find.bySemanticsLabel('scam_alert.dismiss'), findsNothing);
    });
  });

  group('ScamAlert — expand / collapse', () {
    testWidgets('collapsed by default — reason list hidden', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () {},
        ),
      );
      expect(
        find.textContaining('scam_alert.reasons.externalPaymentLink'),
        findsNothing,
      );
    });

    testWidgets('tapping expand toggle reveals reasons', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () {},
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(RegExp('scam_alert.whyWarning')).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('scam_alert.reasons.externalPaymentLink'),
        findsOneWidget,
      );
    });

    testWidgets('initiallyExpanded true → reasons visible on first frame', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [
            ScamAlertReason.externalPaymentLink,
            ScamAlertReason.phoneNumberRequest,
          ],
          onReport: () {},
          initiallyExpanded: true,
        ),
      );
      expect(
        find.textContaining('scam_alert.reasons.externalPaymentLink'),
        findsOneWidget,
      );
      expect(
        find.textContaining('scam_alert.reasons.phoneNumberRequest'),
        findsOneWidget,
      );
    });

    testWidgets('expand toggle switches to collapse semantics', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.other],
          onReport: () {},
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('scam_alert.whyWarning')),
        findsWidgets,
      );
      await tester.tap(
        find.bySemanticsLabel(RegExp('scam_alert.whyWarning')).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('scam_alert.whyWarningHide')),
        findsWidgets,
      );
    });
  });

  group('ScamAlert — invariants', () {
    test('empty reasons list throws', () {
      expect(
        () =>
            ScamAlert(confidence: ScamAlertConfidence.high, reasons: const []),
        throwsAssertionError,
      );
    });
  });

  group('ScamAlert — accessibility', () {
    testWidgets('live-region Semantics label present for high', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.other],
          onReport: () {},
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('scam_alert.a11yHigh')),
        findsWidgets,
      );
    });

    testWidgets('live-region Semantics label present for low', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.other],
        ),
      );
      expect(find.bySemanticsLabel(RegExp('scam_alert.a11yLow')), findsWidgets);
    });

    testWidgets('Report button tap target (InkWell) is ≥ 44 high', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () {},
        ),
      );
      // Finding the InkWell (not any ancestor Container) so the assertion
      // measures the actual touch surface, not the outer card padding.
      final reportInkWell = find.ancestor(
        of: find.textContaining('scam_alert.report'),
        matching: find.byType(InkWell),
      );
      expect(reportInkWell, findsOneWidget);
      final size = tester.getSize(reportInkWell);
      expect(size.height, greaterThanOrEqualTo(44));
      // Width grows with Expanded parent; in the narrow test viewport it
      // should still be well above 44.
      expect(size.width, greaterThanOrEqualTo(44));
    });

    testWidgets('Expand toggle tap target is ≥ 44×44', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.other],
          onReport: () {},
        ),
      );
      final toggleInkWell = find.ancestor(
        of: find.byIcon(PhosphorIcons.caretDown()),
        matching: find.byType(InkWell),
      );
      expect(toggleInkWell, findsOneWidget);
      final size = tester.getSize(toggleInkWell);
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });

    testWidgets('Dismiss icon tap target (low confidence) is ≥ 44×44', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onDismiss: () {},
        ),
      );
      final dismissInkWell = find.ancestor(
        of: find.byIcon(PhosphorIcons.x()),
        matching: find.byType(InkWell),
      );
      expect(dismissInkWell, findsOneWidget);
      final size = tester.getSize(dismissInkWell);
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });
  });

  group('ScamAlert — dark theme', () {
    testWidgets('high renders in dark without exception', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
          onReport: () {},
          initiallyExpanded: true,
        ),
        theme: DeelmarktTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('low renders in dark without exception', (tester) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamAlertConfidence.low,
          reasons: const [ScamAlertReason.phoneNumberRequest],
        ),
        theme: DeelmarktTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ScamAlertReason — l10n key mapping', () {
    test(
      'every enum value maps to a unique key under scam_alert.reasons.*',
      () {
        final keys = <String>{};
        for (final r in ScamAlertReason.values) {
          expect(r.l10nKey.startsWith('scam_alert.reasons.'), isTrue);
          keys.add(r.l10nKey);
        }
        expect(keys.length, ScamAlertReason.values.length);
      },
    );
  });
}
