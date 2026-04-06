import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/widgets/trust/scam_alert.dart';
import 'package:deelmarkt/widgets/trust/scam_alert_reason.dart';

import '../../helpers/pump_app.dart';

void main() {
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
      final reportInkWell = find.ancestor(
        of: find.textContaining('scam_alert.report'),
        matching: find.byType(InkWell),
      );
      expect(reportInkWell, findsOneWidget);
      final size = tester.getSize(reportInkWell);
      expect(size.height, greaterThanOrEqualTo(44));
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
}
