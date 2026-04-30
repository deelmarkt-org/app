import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/widgets/trust/scam_flag_statement_parts.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ScamStatementSection', () {
    testWidgets('renders title above its child in a Column', (tester) async {
      await pumpTestWidget(
        tester,
        const ScamStatementSection(
          title: 'WHAT WAS FLAGGED',
          child: Text('listing/abc-123'),
        ),
      );

      expect(find.text('WHAT WAS FLAGGED'), findsOneWidget);
      expect(find.text('listing/abc-123'), findsOneWidget);

      final titleY = tester.getTopLeft(find.text('WHAT WAS FLAGGED')).dy;
      final childY = tester.getTopLeft(find.text('listing/abc-123')).dy;
      expect(titleY, lessThan(childY));
    });

    testWidgets('uses CrossAxisAlignment.start for the inner Column', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ScamStatementSection(title: 'WHY', child: SizedBox.shrink()),
      );

      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(ScamStatementSection),
          matching: find.byType(Column),
        ),
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });
  });

  group('ScamReasonsList', () {
    testWidgets('renders one row per ScamReason in given order', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ScamReasonsList(
          reasons: [
            ScamReason.suspiciousPricing,
            ScamReason.urgencyPressure,
            ScamReason.fakeEscrow,
          ],
        ),
      );

      expect(find.text('scam_alert.reason.suspicious_pricing'), findsOneWidget);
      expect(find.text('scam_alert.reason.urgency_pressure'), findsOneWidget);
      expect(find.text('scam_alert.reason.fake_escrow'), findsOneWidget);

      // Vertical order matches input order — top to bottom.
      final yPricing =
          tester
              .getTopLeft(find.text('scam_alert.reason.suspicious_pricing'))
              .dy;
      final yUrgency =
          tester.getTopLeft(find.text('scam_alert.reason.urgency_pressure')).dy;
      final yEscrow =
          tester.getTopLeft(find.text('scam_alert.reason.fake_escrow')).dy;
      expect(yPricing, lessThan(yUrgency));
      expect(yUrgency, lessThan(yEscrow));
    });

    testWidgets('renders empty Column for empty reasons list', (tester) async {
      // Defensive: the parent ScamFlagStatement entity asserts non-empty,
      // but the widget itself does not — it should render gracefully if
      // ever called with []. Guards against future mis-use crashes.
      await pumpTestWidget(tester, const ScamReasonsList(reasons: []));

      expect(find.byType(ScamReasonsList), findsOneWidget);
      expect(
        find.byType(Padding),
        findsNothing,
        reason: 'no per-reason rows should be created',
      );
    });

    testWidgets(
      'covers every ScamReason enum value via localizationKey contract',
      (tester) async {
        // Renders the FULL set so a future enum addition without a copy
        // key shows up here as a missing l10n warning rather than as a
        // silent gap on the suspension gate.
        await pumpTestWidget(
          tester,
          const ScamReasonsList(reasons: ScamReason.values),
        );

        for (final reason in ScamReason.values) {
          expect(
            find.text(reason.localizationKey),
            findsOneWidget,
            reason: '${reason.name} must surface a localizationKey',
          );
        }
      },
    );
  });

  group('ScamDecisionMetadata', () {
    ScamFlagStatement statement({
      String modelVersion = 'scam-classifier-v1.4.0',
      String policyVersion = 'policy-2026-04',
      double score = 0.87,
    }) {
      return ScamFlagStatement(
        ruleId: 'r1',
        reasons: const [ScamReason.other],
        score: score,
        modelVersion: modelVersion,
        policyVersion: policyVersion,
        flaggedAt: DateTime(2026, 4, 30),
        contentRef: 'listing/x',
      );
    }

    testWidgets('renders all four DSA-required transparency strings', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamDecisionMetadata(statement: statement()),
      );

      // .tr returns the literal key path in tests — verify all four
      // l10n keys are surfaced.
      expect(
        find.text('dsa.statement_of_reasons.automated_indicator'),
        findsOneWidget,
      );
      expect(find.text('dsa.statement_of_reasons.confidence'), findsOneWidget);
      expect(
        find.text('dsa.statement_of_reasons.model_version'),
        findsOneWidget,
      );
      expect(
        find.text('dsa.statement_of_reasons.policy_version'),
        findsOneWidget,
      );
    });
  });
}
