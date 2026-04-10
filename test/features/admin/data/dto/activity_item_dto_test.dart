import 'package:deelmarkt/features/admin/data/dto/activity_item_dto.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityItemDto', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'listingRemoved',
          'title': 'Listing #4321 verwijderd',
          'subtitle': 'Reden: schending van het advertentiebeleid',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        final result = ActivityItemDto.fromJson(json);

        expect(result.id, 'act-001');
        expect(result.type, ActivityItemType.listingRemoved);
        expect(result.title, 'Listing #4321 verwijderd');
        expect(result.subtitle, 'Reden: schending van het advertentiebeleid');
        expect(result.timestamp, DateTime.utc(2026, 4, 10, 12));
      });

      test('throws FormatException when id is missing', () {
        final json = <String, dynamic>{
          'type': 'listingRemoved',
          'title': 'Some title',
          'subtitle': 'Some subtitle',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        expect(
          () => ActivityItemDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when title is missing', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'listingRemoved',
          'subtitle': 'Some subtitle',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        expect(
          () => ActivityItemDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when subtitle is missing', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'listingRemoved',
          'title': 'Some title',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        expect(
          () => ActivityItemDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('defaults to systemUpdate for unknown type', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'unknownType',
          'title': 'Some title',
          'subtitle': 'Some subtitle',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        final result = ActivityItemDto.fromJson(json);

        expect(result.type, ActivityItemType.systemUpdate);
      });

      test('defaults to systemUpdate when type is null', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'title': 'Some title',
          'subtitle': 'Some subtitle',
          'timestamp': '2026-04-10T12:00:00.000Z',
        };

        final result = ActivityItemDto.fromJson(json);

        expect(result.type, ActivityItemType.systemUpdate);
      });

      test('throws FormatException for invalid timestamp string', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'userVerified',
          'title': 'Some title',
          'subtitle': 'Some subtitle',
          'timestamp': 'not-a-date',
        };

        expect(
          () => ActivityItemDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when timestamp is missing', () {
        final json = <String, dynamic>{
          'id': 'act-001',
          'type': 'userVerified',
          'title': 'Some title',
          'subtitle': 'Some subtitle',
        };

        expect(
          () => ActivityItemDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromJsonList', () {
      test('parses list of valid items', () {
        final jsonList = <dynamic>[
          <String, dynamic>{
            'id': 'act-001',
            'type': 'listingRemoved',
            'title': 'Title 1',
            'subtitle': 'Subtitle 1',
            'timestamp': '2026-04-10T12:00:00.000Z',
          },
          <String, dynamic>{
            'id': 'act-002',
            'type': 'userVerified',
            'title': 'Title 2',
            'subtitle': 'Subtitle 2',
            'timestamp': '2026-04-10T13:00:00.000Z',
          },
        ];

        final results = ActivityItemDto.fromJsonList(jsonList);

        expect(results, hasLength(2));
        expect(results[0].id, 'act-001');
        expect(results[0].type, ActivityItemType.listingRemoved);
        expect(results[1].id, 'act-002');
        expect(results[1].type, ActivityItemType.userVerified);
      });

      test('skips malformed entries with missing required fields', () {
        final jsonList = <dynamic>[
          <String, dynamic>{
            'id': 'act-001',
            'type': 'listingRemoved',
            'title': 'Title 1',
            'subtitle': 'Subtitle 1',
            'timestamp': '2026-04-10T12:00:00.000Z',
          },
          <String, dynamic>{
            'type': 'userVerified',
            'title': 'Missing id',
            'subtitle': 'Subtitle',
          },
          <String, dynamic>{
            'id': 'act-003',
            'type': 'systemUpdate',
            'title': 'Title 3',
            'subtitle': 'Subtitle 3',
            'timestamp': '2026-04-10T14:00:00.000Z',
          },
        ];

        final results = ActivityItemDto.fromJsonList(jsonList);

        expect(results, hasLength(2));
        expect(results[0].id, 'act-001');
        expect(results[1].id, 'act-003');
      });

      test('skips non-Map entries', () {
        final jsonList = <dynamic>[
          'not a map',
          42,
          null,
          <String, dynamic>{
            'id': 'act-001',
            'type': 'listingRemoved',
            'title': 'Title 1',
            'subtitle': 'Subtitle 1',
            'timestamp': '2026-04-10T12:00:00.000Z',
          },
        ];

        final results = ActivityItemDto.fromJsonList(jsonList);

        expect(results, hasLength(1));
        expect(results[0].id, 'act-001');
      });

      test('returns empty list for empty input', () {
        final results = ActivityItemDto.fromJsonList(<dynamic>[]);

        expect(results, isEmpty);
      });
    });
  });
}
