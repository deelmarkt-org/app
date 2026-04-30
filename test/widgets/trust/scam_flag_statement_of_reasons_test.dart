import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/trust/scam_flag_statement_of_reasons.dart';

import '../../helpers/pump_app.dart';

void main() {
  ScamFlagStatement statement({
    List<ScamReason>? reasons,
    double score = 0.87,
    String contentRef = 'listing/abc-123',
    String? contentDisplayLabel,
  }) {
    return ScamFlagStatement(
      ruleId: 'link_pattern_v3',
      reasons:
          reasons ??
          const [ScamReason.externalPaymentLink, ScamReason.urgencyPressure],
      score: score,
      modelVersion: 'scam-classifier-v1.4.0',
      policyVersion: 'policy-2026-04',
      flaggedAt: DateTime(2026, 4, 30),
      contentRef: contentRef,
      contentDisplayLabel: contentDisplayLabel,
    );
  }

  group('ScamFlagStatementOfReasons', () {
    testWidgets('renders the four DSA-required transparency sections', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(statement: statement()),
      );

      expect(find.text('dsa.statement_of_reasons.headline'), findsOneWidget);
      expect(
        find.text('dsa.statement_of_reasons.what_flagged'),
        findsOneWidget,
      );
      expect(find.text('dsa.statement_of_reasons.why'), findsOneWidget);
      expect(find.text('dsa.statement_of_reasons.how'), findsOneWidget);
    });

    testWidgets(
      'renders contentDisplayLabel verbatim when supplied (preferred UX path)',
      (tester) async {
        await pumpTestWidget(
          tester,
          ScamFlagStatementOfReasons(
            statement: statement(
              contentRef: 'listing/xyz-987',
              contentDisplayLabel: 'Mountain bike — listed 2026-04-25',
            ),
          ),
        );

        // Human-readable label takes precedence over the opaque ref.
        expect(find.text('Mountain bike — listed 2026-04-25'), findsOneWidget);
        expect(
          find.text('listing/xyz-987'),
          findsNothing,
          reason: 'opaque ref must NOT leak when a display label is set',
        );
      },
    );

    testWidgets(
      'falls back to a localised content-kind label when displayLabel is null',
      (tester) async {
        await pumpTestWidget(
          tester,
          ScamFlagStatementOfReasons(
            statement: statement(contentRef: 'listing/xyz-987'),
          ),
        );

        expect(
          find.text('dsa.statement_of_reasons.content_kind.listing'),
          findsOneWidget,
          reason: 'must derive a kind-keyed l10n string from contentRef',
        );
        expect(
          find.text('listing/xyz-987'),
          findsNothing,
          reason: 'raw "listing/xyz-987" must not be surfaced to users',
        );
      },
    );

    testWidgets('unknown content kind falls back to the generic l10n bucket', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(
          statement: statement(contentRef: 'mystery-kind/zzz'),
        ),
      );

      expect(
        find.text('dsa.statement_of_reasons.content_kind.generic'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders one localised reason per ScamReason (preserves order)',
      (tester) async {
        await pumpTestWidget(
          tester,
          ScamFlagStatementOfReasons(
            statement: statement(
              reasons: const [
                ScamReason.suspiciousPricing,
                ScamReason.urgencyPressure,
                ScamReason.fakeEscrow,
              ],
            ),
          ),
        );

        expect(
          find.text('scam_alert.reason.suspicious_pricing'),
          findsOneWidget,
        );
        expect(find.text('scam_alert.reason.urgency_pressure'), findsOneWidget);
        expect(find.text('scam_alert.reason.fake_escrow'), findsOneWidget);
      },
    );

    testWidgets('surfaces model version + policy version + automated indicator '
        'l10n keys (namedArgs substitution verified at .arb load time, not '
        'in widget tests where .tr returns the raw key path)', (tester) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(statement: statement()),
      );

      expect(
        find.text('dsa.statement_of_reasons.automated_indicator'),
        findsOneWidget,
      );
      expect(
        find.text('dsa.statement_of_reasons.model_version'),
        findsOneWidget,
      );
      expect(
        find.text('dsa.statement_of_reasons.policy_version'),
        findsOneWidget,
      );
      expect(find.text('dsa.statement_of_reasons.confidence'), findsOneWidget);
    });

    testWidgets('hides Appeal CTA when onAppeal is null', (tester) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(statement: statement()),
      );

      expect(find.byType(DeelButton), findsNothing);
      expect(find.text('dsa.statement_of_reasons.appeal_cta'), findsNothing);
    });

    testWidgets('shows Appeal CTA + fires callback when onAppeal is provided', (
      tester,
    ) async {
      var taps = 0;
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(
          statement: statement(),
          onAppeal: () => taps++,
        ),
      );

      expect(find.byType(DeelButton), findsOneWidget);
      expect(find.text('dsa.statement_of_reasons.appeal_cta'), findsOneWidget);

      await tester.tap(find.text('dsa.statement_of_reasons.appeal_cta'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('exposes a Semantics container with a11y label', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(statement: statement()),
      );

      // Find the outer-most Semantics ancestor we authored — the widget
      // wraps everything in a Semantics(label: 'dsa.statement_of_reasons.a11y').
      final ancestors = find.ancestor(
        of: find.text('dsa.statement_of_reasons.headline'),
        matching: find.byType(Semantics),
      );
      final ours =
          tester
              .widgetList<Semantics>(ancestors)
              .where(
                (s) => s.properties.label == 'dsa.statement_of_reasons.a11y',
              )
              .toList();
      expect(
        ours,
        isNotEmpty,
        reason: 'authored a11y Semantics wrapper must be in the tree',
      );
      expect(ours.single.container, isTrue);
    });

    testWidgets('renders without exception in dark mode', (tester) async {
      await pumpTestWidget(
        tester,
        ScamFlagStatementOfReasons(statement: statement()),
        theme: ThemeData.dark(),
      );

      expect(find.byType(ScamFlagStatementOfReasons), findsOneWidget);
      expect(find.text('dsa.statement_of_reasons.headline'), findsOneWidget);
    });
  });
}
