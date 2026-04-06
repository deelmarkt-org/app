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
      expect(find.textContaining('scam_alert.dismiss'), findsNothing);
    });

    testWidgets('asserts onReport is required for high confidence', (
      tester,
    ) async {
      expect(
        () => ScamAlert(
          confidence: ScamAlertConfidence.high,
          reasons: const [ScamAlertReason.externalPaymentLink],
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
      await tester.tap(find.byIcon(PhosphorIcons.x()));
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
      await tester.tap(find.byIcon(PhosphorIcons.caretDown()));
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
      expect(find.byIcon(PhosphorIcons.caretDown()), findsOneWidget);
      await tester.tap(find.byIcon(PhosphorIcons.caretDown()));
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
