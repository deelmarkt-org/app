import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/scam_flag_statement.dart';

void main() {
  ScamFlagStatement build({
    String ruleId = 'link_pattern_v3',
    List<ScamReason>? reasons,
    double score = 0.87,
    String modelVersion = 'scam-classifier-v1.4.0',
    String policyVersion = 'policy-2026-04',
    DateTime? flaggedAt,
    String contentRef = 'listing/abc-123',
  }) {
    return ScamFlagStatement(
      ruleId: ruleId,
      reasons: reasons ?? const [ScamReason.externalPaymentLink],
      score: score,
      modelVersion: modelVersion,
      policyVersion: policyVersion,
      flaggedAt: flaggedAt ?? DateTime(2026, 4, 30),
      contentRef: contentRef,
    );
  }

  group('ScamFlagStatement', () {
    test('confidencePercent rounds down to integer percentage', () {
      expect(
        build().confidencePercent,
        87,
        reason: 'default 0.87 must surface as 87%',
      );
      expect(
        build(score: 0.499).confidencePercent,
        49,
        reason: 'rounds down — 49%, not 50%',
      );
      expect(build(score: 1.0).confidencePercent, 100);
      expect(build(score: 0.0).confidencePercent, 0);
    });

    test('asserts score within [0.0, 1.0]', () {
      expect(() => build(score: -0.1), throwsA(isA<AssertionError>()));
      expect(() => build(score: 1.1), throwsA(isA<AssertionError>()));
    });

    test('asserts reasons must not be empty', () {
      expect(() => build(reasons: const []), throwsA(isA<AssertionError>()));
    });

    test('Equatable equality compares all transparency fields', () {
      final a = build();
      final b = build();
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      // Differing model version → not equal (DSA Art. 17(3)(b) requires
      // the appellant be able to cite the exact model — equality must
      // catch model drift).
      expect(a == build(modelVersion: 'v9.9.9'), isFalse);
      // Differing policy version → not equal.
      expect(a == build(policyVersion: 'policy-2099-12'), isFalse);
      // Differing rule id → not equal (different rule = different decision).
      expect(a == build(ruleId: 'phone_regex_nl'), isFalse);
    });

    test('preserves order of reasons (UI renders top→bottom)', () {
      final stmt = build(
        reasons: const [
          ScamReason.suspiciousPricing,
          ScamReason.urgencyPressure,
          ScamReason.externalPaymentLink,
        ],
      );
      expect(stmt.reasons, [
        ScamReason.suspiciousPricing,
        ScamReason.urgencyPressure,
        ScamReason.externalPaymentLink,
      ]);
    });
  });
}
