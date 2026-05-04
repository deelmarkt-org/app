import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/profile/data/dto/scam_flag_statement_dto.dart';

Map<String, dynamic> _validJson({
  String ruleId = 'link_pattern_v3',
  List<dynamic> reasons = const ['external_payment_link', 'urgency_pressure'],
  num score = 0.823,
  String modelVersion = 'scam-classifier-v1.4.0',
  String policyVersion = 'policy-2026-04',
  String flaggedAt = '2026-04-30T12:00:00Z',
  String contentRef = 'message/abc-123',
  String? contentDisplayLabel = 'iPhone 14 Pro 256GB - Demo Listing',
}) => {
  'rule_id': ruleId,
  'reasons': reasons,
  'score': score,
  'model_version': modelVersion,
  'policy_version': policyVersion,
  'flagged_at': flaggedAt,
  'content_ref': contentRef,
  if (contentDisplayLabel != null) 'content_display_label': contentDisplayLabel,
};

void main() {
  group('ScamFlagStatementDto.fromJson', () {
    test('parses a valid RPC payload', () {
      final result = ScamFlagStatementDto.fromJson(_validJson());

      expect(result, isA<ScamFlagStatement>());
      expect(result.ruleId, 'link_pattern_v3');
      expect(result.reasons, [
        ScamReason.externalPaymentLink,
        ScamReason.urgencyPressure,
      ]);
      expect(result.score, closeTo(0.823, 1e-9));
      expect(result.modelVersion, 'scam-classifier-v1.4.0');
      expect(result.policyVersion, 'policy-2026-04');
      expect(result.flaggedAt.isUtc, isTrue);
      expect(result.contentRef, 'message/abc-123');
      expect(result.contentDisplayLabel, 'iPhone 14 Pro 256GB - Demo Listing');
    });

    test('contentDisplayLabel is optional', () {
      final result = ScamFlagStatementDto.fromJson(
        _validJson(contentDisplayLabel: null),
      );
      expect(result.contentDisplayLabel, isNull);
    });

    test('unknown reason strings fall back to ScamReason.other', () {
      final result = ScamFlagStatementDto.fromJson(
        _validJson(reasons: const ['external_payment_link', 'mystery_reason']),
      );
      expect(result.reasons, [
        ScamReason.externalPaymentLink,
        ScamReason.other,
      ]);
    });

    test('integer score is accepted (server may serialise 1.0 as 1)', () {
      final result = ScamFlagStatementDto.fromJson(_validJson(score: 1));
      expect(result.score, 1.0);
    });

    test('throws on missing required field (rule_id)', () {
      final json = _validJson()..remove('rule_id');
      expect(
        () => ScamFlagStatementDto.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on empty reasons array', () {
      expect(
        () => ScamFlagStatementDto.fromJson(_validJson(reasons: const [])),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when reasons contains only non-string values', () {
      expect(
        () => ScamFlagStatementDto.fromJson(
          _validJson(reasons: const [42, false]),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on unparseable flagged_at', () {
      expect(
        () =>
            ScamFlagStatementDto.fromJson(_validJson(flaggedAt: 'not-a-date')),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on score outside [0, 1] (entity invariant)', () {
      expect(
        () => ScamFlagStatementDto.fromJson(_validJson(score: 1.5)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ScamFlagStatementDto.fromJsonOrNull', () {
    test('returns null for null input (no active flag)', () {
      expect(ScamFlagStatementDto.fromJsonOrNull(null), isNull);
    });

    test('returns null for unexpected non-Map input (logged + degrades)', () {
      expect(ScamFlagStatementDto.fromJsonOrNull('not an object'), isNull);
      expect(ScamFlagStatementDto.fromJsonOrNull([1, 2, 3]), isNull);
    });

    test('parses a valid Map', () {
      final result = ScamFlagStatementDto.fromJsonOrNull(_validJson());
      expect(result, isNotNull);
      expect(result!.ruleId, 'link_pattern_v3');
    });
  });
}
