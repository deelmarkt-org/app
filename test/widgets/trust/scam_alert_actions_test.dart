import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/widgets/trust/scam_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Semantics regression tests for _ReportButton and _InlineDismissButton.
///
/// These are part-of private classes in scam_alert_actions.dart, tested
/// through the public [ScamAlert] widget API.
void main() {
  group('ScamAlert actions — Semantics labels (issue #156 H3)', () {
    testWidgets('report button has Semantics with button:true and a label', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamConfidence.high,
          reasons: const [ScamReason.urgencyPressure],
          onReport: () {},
        ),
      );

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();

      final reportButtonSemantics = semanticsList.where(
        (s) =>
            s.properties.button == true &&
            s.properties.label != null &&
            s.properties.label!.isNotEmpty,
      );

      expect(
        reportButtonSemantics,
        isNotEmpty,
        reason:
            'Report button must have a non-empty Semantics label '
            'for TalkBack/VoiceOver (WCAG 4.1.2)',
      );
    });

    testWidgets('dismiss button has Semantics with button:true and a label', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamAlert(
          confidence: ScamConfidence.low,
          reasons: const [ScamReason.urgencyPressure],
          onDismiss: () {},
        ),
      );

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();

      final dismissButtonSemantics = semanticsList.where(
        (s) =>
            s.properties.button == true &&
            s.properties.label != null &&
            s.properties.label!.isNotEmpty,
      );

      expect(
        dismissButtonSemantics,
        isNotEmpty,
        reason:
            'Dismiss button must have a non-empty Semantics label '
            'for TalkBack/VoiceOver (WCAG 4.1.2)',
      );
    });
  });
}
