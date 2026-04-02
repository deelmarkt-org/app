import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/dto/review_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

void main() {
  group('ReviewDto.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = <String, dynamic>{
        'id': 'review-001',
        'reviewer_id': 'user-002',
        'reviewer_name': 'Maria Jansen',
        'reviewee_id': 'user-001',
        'listing_id': 'listing-001',
        'rating': 4.5,
        'text': 'Great seller!',
        'created_at': '2026-03-15T10:00:00Z',
      };

      final result = ReviewDto.fromJson(json);

      expect(result, isA<ReviewEntity>());
      expect(result.id, 'review-001');
      expect(result.rating, 4.5);
      expect(result.text, 'Great seller!');
    });

    test('parses integer rating', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 5,
        'text': 'P',
        'created_at': '2026-03-15T10:00:00Z',
      };
      expect(ReviewDto.fromJson(json).rating, 5.0);
    });

    test('parses reviewer_avatar_url when present', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'text': 'G',
        'created_at': '2026-03-15T10:00:00Z',
        'reviewer_avatar_url': 'https://example.com/a.jpg',
      };
      expect(
        ReviewDto.fromJson(json).reviewerAvatarUrl,
        'https://example.com/a.jpg',
      );
    });

    test('defaults reviewer_avatar_url to null', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'text': 'G',
        'created_at': '2026-03-15T10:00:00Z',
      };
      expect(ReviewDto.fromJson(json).reviewerAvatarUrl, isNull);
    });

    test('uses DateTime.now for invalid created_at string', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'text': 'G',
        'created_at': 'invalid-date',
      };
      expect(ReviewDto.fromJson(json).createdAt, isNotNull);
    });

    test('uses DateTime.now when created_at is not a string', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'text': 'G',
        'created_at': 12345,
      };
      expect(ReviewDto.fromJson(json).createdAt, isNotNull);
    });

    test('throws FormatException for missing id', () {
      final json = <String, dynamic>{
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'text': 'G',
        'created_at': '2026-03-15T10:00:00Z',
      };
      expect(() => ReviewDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing rating', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'text': 'G',
        'created_at': '2026-03-15T10:00:00Z',
      };
      expect(() => ReviewDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing text', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'reviewer_id': 'u2',
        'reviewer_name': 'M',
        'reviewee_id': 'u1',
        'listing_id': 'l1',
        'rating': 4.0,
        'created_at': '2026-03-15T10:00:00Z',
      };
      expect(() => ReviewDto.fromJson(json), throwsFormatException);
    });
  });

  group('ReviewDto.fromJsonList', () {
    test('parses a valid list', () {
      final jsonList = <dynamic>[
        <String, dynamic>{
          'id': 'r1',
          'reviewer_id': 'u2',
          'reviewer_name': 'Maria',
          'reviewee_id': 'u1',
          'listing_id': 'l1',
          'rating': 5.0,
          'text': 'Excellent',
          'created_at': '2026-03-15T10:00:00Z',
        },
        <String, dynamic>{
          'id': 'r2',
          'reviewer_id': 'u3',
          'reviewer_name': 'Pieter',
          'reviewee_id': 'u1',
          'listing_id': 'l2',
          'rating': 4.0,
          'text': 'Good',
          'created_at': '2026-03-10T10:00:00Z',
        },
      ];
      expect(ReviewDto.fromJsonList(jsonList).length, 2);
    });

    test('skips malformed entries', () {
      final jsonList = <dynamic>[
        <String, dynamic>{
          'id': 'r1',
          'reviewer_id': 'u2',
          'reviewer_name': 'Maria',
          'reviewee_id': 'u1',
          'listing_id': 'l1',
          'rating': 5.0,
          'text': 'E',
          'created_at': '2026-03-15T10:00:00Z',
        },
        <String, dynamic>{'id': 'r2'},
      ];
      expect(ReviewDto.fromJsonList(jsonList).length, 1);
    });

    test('skips non-map entries', () {
      final jsonList = <dynamic>[
        'not a map',
        42,
        <String, dynamic>{
          'id': 'r1',
          'reviewer_id': 'u2',
          'reviewer_name': 'Maria',
          'reviewee_id': 'u1',
          'listing_id': 'l1',
          'rating': 5.0,
          'text': 'E',
          'created_at': '2026-03-15T10:00:00Z',
        },
      ];
      expect(ReviewDto.fromJsonList(jsonList).length, 1);
    });

    test('returns empty list for empty input', () {
      expect(ReviewDto.fromJsonList([]), isEmpty);
    });
  });
}
