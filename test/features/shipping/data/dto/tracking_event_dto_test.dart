import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/data/dto/tracking_event_dto.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

void main() {
  group('TrackingEventDto', () {
    group('fromJson', () {
      test('parses a complete JSON row', () {
        final event = TrackingEventDto.fromJson(_validJson());

        expect(event.id, 'evt-001');
        expect(event.status, TrackingStatus.inTransit);
        expect(event.description, 'Pakket in sorteercentrum');
        expect(event.location, 'Amsterdam');
      });

      test('parses all status values correctly', () {
        final cases = {
          'label_created': TrackingStatus.labelCreated,
          'dropped_off': TrackingStatus.droppedOff,
          'picked_up': TrackingStatus.pickedUp,
          'in_transit': TrackingStatus.inTransit,
          'out_for_delivery': TrackingStatus.outForDelivery,
          'delivered': TrackingStatus.delivered,
          'delivery_failed': TrackingStatus.deliveryFailed,
          'returned': TrackingStatus.returned,
        };

        for (final entry in cases.entries) {
          final json = _validJson(status: entry.key);
          final event = TrackingEventDto.fromJson(json);
          expect(event.status, entry.value, reason: 'status: ${entry.key}');
        }
      });

      test('defaults unknown status to inTransit', () {
        final json = _validJson(status: 'unknown');
        final event = TrackingEventDto.fromJson(json);
        expect(event.status, TrackingStatus.inTransit);
      });

      test('handles null optional fields', () {
        final json = _validJson()..remove('location');
        final event = TrackingEventDto.fromJson(json);
        expect(event.location, isNull);
      });

      test('throws FormatException on missing id', () {
        final json = _validJson()..remove('id');
        expect(
          () => TrackingEventDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromJsonList', () {
      test('parses a list and skips non-maps', () {
        final list = [_validJson(), null, _validJson(id: 'evt-002')];
        final events = TrackingEventDto.fromJsonList(list);
        expect(events, hasLength(2));
      });
    });
  });
}

Map<String, dynamic> _validJson({
  String id = 'evt-001',
  String status = 'in_transit',
}) {
  return {
    'id': id,
    'status': status,
    'description': 'Pakket in sorteercentrum',
    'occurred_at': '2026-04-09T14:30:00Z',
    'location': 'Amsterdam',
  };
}
