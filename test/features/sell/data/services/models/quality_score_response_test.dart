import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/data/services/models/quality_score_response.dart';

void main() {
  group('QualityScoreResponse.fromJson', () {
    test('parses a complete passing response', () {
      final result = QualityScoreResponse.fromJson(const {
        'score': 100,
        'can_publish': true,
        'breakdown': [
          {
            'name': 'sell.photos',
            'points': 25,
            'max_points': 25,
            'passed': true,
            'tip_key': null,
          },
        ],
      });
      expect(result.score, 100);
      expect(result.canPublish, true);
      expect(result.breakdown, hasLength(1));
      expect(result.breakdown.first.name, 'sell.photos');
      expect(result.breakdown.first.tipKey, isNull);
    });

    test('parses a response with mixed passing + failing fields', () {
      final result = QualityScoreResponse.fromJson(const {
        'score': 35,
        'can_publish': false,
        'breakdown': [
          {
            'name': 'sell.photos',
            'points': 25,
            'max_points': 25,
            'passed': true,
            'tip_key': null,
          },
          {
            'name': 'sell.title',
            'points': 0,
            'max_points': 15,
            'passed': false,
            'tip_key': 'sell.titleTip',
          },
          {
            'name': 'sell.condition',
            'points': 10,
            'max_points': 10,
            'passed': true,
            'tip_key': null,
          },
        ],
      });
      expect(result.score, 35);
      expect(result.canPublish, false);
      expect(result.breakdown, hasLength(3));
      expect(result.breakdown[1].passed, false);
      expect(result.breakdown[1].tipKey, 'sell.titleTip');
    });

    test('throws FormatException when score is missing', () {
      expect(
        () => QualityScoreResponse.fromJson(const {
          'can_publish': true,
          'breakdown': <Map<String, dynamic>>[],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when score has the wrong type', () {
      expect(
        () => QualityScoreResponse.fromJson(const {
          'score': '100',
          'can_publish': true,
          'breakdown': <Map<String, dynamic>>[],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when can_publish is missing', () {
      expect(
        () => QualityScoreResponse.fromJson(const {
          'score': 50,
          'breakdown': <Map<String, dynamic>>[],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when breakdown is not a list', () {
      expect(
        () => QualityScoreResponse.fromJson(const {
          'score': 50,
          'can_publish': true,
          'breakdown': 'not a list',
        }),
        throwsFormatException,
      );
    });

    test('skips breakdown entries that are not maps', () {
      final result = QualityScoreResponse.fromJson(const {
        'score': 25,
        'can_publish': false,
        'breakdown': [
          {
            'name': 'sell.photos',
            'points': 25,
            'max_points': 25,
            'passed': true,
            'tip_key': null,
          },
          'garbage',
          42,
        ],
      });
      expect(result.breakdown, hasLength(1));
    });
  });

  group('QualityScoreFieldResponse.fromJson', () {
    test('parses a failing field with tip_key', () {
      final field = QualityScoreFieldResponse.fromJson(const {
        'name': 'sell.description',
        'points': 0,
        'max_points': 20,
        'passed': false,
        'tip_key': 'sell.descriptionTip',
      });
      expect(field.name, 'sell.description');
      expect(field.points, 0);
      expect(field.maxPoints, 20);
      expect(field.passed, false);
      expect(field.tipKey, 'sell.descriptionTip');
    });

    test('accepts missing tip_key (falls back to null)', () {
      final field = QualityScoreFieldResponse.fromJson(const {
        'name': 'sell.photos',
        'points': 25,
        'max_points': 25,
        'passed': true,
      });
      expect(field.tipKey, isNull);
    });

    test('throws on missing required fields', () {
      expect(
        () => QualityScoreFieldResponse.fromJson(const {'name': 'sell.photos'}),
        throwsFormatException,
      );
    });
  });
}
