import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/dto/user_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  group('UserDto', () {
    final sampleJson = {
      'id': 'user-001',
      'display_name': 'Jan de Vries',
      'avatar_url': 'https://example.com/avatar.jpg',
      'location': 'Amsterdam',
      'kyc_level': 'level1',
      'badges': ['emailVerified', 'phoneVerified', 'fastResponder'],
      'average_rating': 4.7,
      'review_count': 23,
      'response_time_minutes': 15,
      'created_at': '2025-06-01T00:00:00Z',
    };

    test('fromJson parses all fields', () {
      final entity = UserDto.fromJson(sampleJson);

      expect(entity.id, 'user-001');
      expect(entity.displayName, 'Jan de Vries');
      expect(entity.avatarUrl, 'https://example.com/avatar.jpg');
      expect(entity.location, 'Amsterdam');
      expect(entity.kycLevel, KycLevel.level1);
      expect(entity.badges, [
        BadgeType.emailVerified,
        BadgeType.phoneVerified,
        BadgeType.fastResponder,
      ]);
      expect(entity.averageRating, 4.7);
      expect(entity.reviewCount, 23);
      expect(entity.responseTimeMinutes, 15);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'user-002',
        'display_name': 'Maria Jansen',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final entity = UserDto.fromJson(minimalJson);

      expect(entity.avatarUrl, isNull);
      expect(entity.location, isNull);
      expect(entity.kycLevel, KycLevel.level0);
      expect(entity.badges, isEmpty);
      expect(entity.averageRating, isNull);
      expect(entity.reviewCount, 0);
      expect(entity.responseTimeMinutes, isNull);
    });

    test('fromJson parses all KYC levels', () {
      for (final level in ['level0', 'level1', 'level2', 'level3', 'level4']) {
        final json = {
          'id': 'user-x',
          'display_name': 'Test',
          'kyc_level': level,
          'created_at': '2026-01-01T00:00:00Z',
        };
        final entity = UserDto.fromJson(json);
        expect(entity.kycLevel.name, level);
      }
    });

    test('fromJson defaults unknown KYC level to level0', () {
      final json = {
        'id': 'user-x',
        'display_name': 'Test',
        'kyc_level': 'unknown_level',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final entity = UserDto.fromJson(json);
      expect(entity.kycLevel, KycLevel.level0);
    });

    test('toJson produces writable fields', () {
      final entity = UserDto.fromJson(sampleJson);
      final json = UserDto.toJson(entity);

      expect(json['id'], 'user-001');
      expect(json['display_name'], 'Jan de Vries');
      expect(json['badges'], [
        'emailVerified',
        'phoneVerified',
        'fastResponder',
      ]);
      expect(json.containsKey('kyc_level'), false);
      expect(json.containsKey('average_rating'), false);
      expect(json.containsKey('review_count'), false);
    });

    test('fromJsonList parses multiple users', () {
      final list = UserDto.fromJsonList([sampleJson, sampleJson]);
      expect(list, hasLength(2));
    });

    test('fromJson throws FormatException on missing required fields', () {
      expect(() => UserDto.fromJson({}), throwsFormatException);
      expect(() => UserDto.fromJson({'id': 'x'}), throwsFormatException);
    });

    test('fromJson handles missing created_at gracefully', () {
      final json = {'id': 'user-x', 'display_name': 'Test'};
      final entity = UserDto.fromJson(json);
      expect(entity.createdAt.year, DateTime.now().year);
    });

    test('fromJsonList skips non-Map entries', () {
      final list = UserDto.fromJsonList([sampleJson, 'invalid', null]);
      expect(list, hasLength(1));
    });
  });
}
