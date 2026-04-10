import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/dto/sanction_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

Map<String, dynamic> _validJson({
  String id = 'sanction-001',
  String userId = 'user-001',
  String type = 'suspension',
  String reason = 'Fraudulent activity',
  String createdAt = '2026-04-01T10:00:00Z',
  String? expiresAt = '2026-04-08T10:00:00Z',
  String? appealedAt,
  String? appealBody,
  String? appealDecision,
  String? resolvedAt,
}) => {
  'id': id,
  'user_id': userId,
  'type': type,
  'reason': reason,
  'created_at': createdAt,
  if (expiresAt != null) 'expires_at': expiresAt,
  if (appealedAt != null) 'appealed_at': appealedAt,
  if (appealBody != null) 'appeal_body': appealBody,
  if (appealDecision != null) 'appeal_decision': appealDecision,
  if (resolvedAt != null) 'resolved_at': resolvedAt,
};

void main() {
  group('SanctionDto.fromJson', () {
    test('parses valid suspension JSON', () {
      final result = SanctionDto.fromJson(_validJson());

      expect(result, isA<SanctionEntity>());
      expect(result.id, 'sanction-001');
      expect(result.userId, 'user-001');
      expect(result.type, SanctionType.suspension);
      expect(result.reason, 'Fraudulent activity');
      expect(result.expiresAt, isNotNull);
    });

    test('parses warning type', () {
      final result = SanctionDto.fromJson(
        _validJson(type: 'warning', expiresAt: null),
      );
      expect(result.type, SanctionType.warning);
      expect(result.expiresAt, isNull);
    });

    test('parses ban type', () {
      final result = SanctionDto.fromJson(
        _validJson(type: 'ban', expiresAt: null),
      );
      expect(result.type, SanctionType.ban);
    });

    test('parses appeal fields', () {
      final result = SanctionDto.fromJson(
        _validJson(
          appealedAt: '2026-04-02T10:00:00Z',
          appealBody: 'I did nothing wrong',
        ),
      );

      expect(result.appealedAt, isNotNull);
      expect(result.appealBody, 'I did nothing wrong');
      expect(result.appealDecision, isNull);
    });

    test('parses upheld appeal decision', () {
      final result = SanctionDto.fromJson(
        _validJson(
          appealedAt: '2026-04-02T10:00:00Z',
          appealBody: 'I appeal',
          appealDecision: 'upheld',
          resolvedAt: '2026-04-04T10:00:00Z',
        ),
      );

      expect(result.appealDecision, AppealDecision.upheld);
      expect(result.resolvedAt, isNotNull);
    });

    test('parses overturned appeal decision', () {
      final result = SanctionDto.fromJson(
        _validJson(
          appealedAt: '2026-04-02T10:00:00Z',
          appealBody: 'I appeal',
          appealDecision: 'overturned',
          resolvedAt: '2026-04-04T10:00:00Z',
        ),
      );

      expect(result.appealDecision, AppealDecision.overturned);
    });

    test('throws FormatException for missing id', () {
      final json = _validJson()..remove('id');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing user_id', () {
      final json = _validJson()..remove('user_id');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing type', () {
      final json = _validJson()..remove('type');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing reason', () {
      final json = _validJson()..remove('reason');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for unknown type', () {
      final json = _validJson(type: 'probation');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for unknown appeal_decision', () {
      final json = _validJson(
        appealedAt: '2026-04-02T10:00:00Z',
        appealBody: 'I appeal',
        appealDecision: 'pending',
      );
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });

    test('null expires_at parses as null', () {
      final json = _validJson(expiresAt: null);
      expect(SanctionDto.fromJson(json).expiresAt, isNull);
    });

    test('invalid created_at throws FormatException', () {
      final json = _validJson(createdAt: 'not-a-date');
      expect(() => SanctionDto.fromJson(json), throwsFormatException);
    });
  });

  group('SanctionDto.fromJsonList', () {
    test('parses a valid list', () {
      final list = [
        _validJson(),
        _validJson(id: 'sanction-002', type: 'warning', expiresAt: null),
      ];
      expect(SanctionDto.fromJsonList(list).length, 2);
    });

    test('skips malformed entries', () {
      final list = [
        _validJson(),
        <String, dynamic>{'id': 'bad'},
      ];
      expect(SanctionDto.fromJsonList(list).length, 1);
    });

    test('skips non-map entries', () {
      final list = ['not-a-map', 42, _validJson()];
      expect(SanctionDto.fromJsonList(list).length, 1);
    });

    test('returns empty list for empty input', () {
      expect(SanctionDto.fromJsonList([]), isEmpty);
    });
  });
}
