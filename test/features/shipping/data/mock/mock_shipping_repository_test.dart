import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

void main() {
  late MockShippingRepository repo;

  setUp(() {
    repo = MockShippingRepository();
  });

  group('MockShippingRepository', () {
    group('getLabel', () {
      test('returns label for known ID', () async {
        final label = await repo.getLabel('ship-001');
        expect(label, isNotNull);
        expect(label!.id, 'ship-001');
        expect(label.carrier, ShippingCarrier.postnl);
        expect(label.trackingNumber, '3SDEVC1234567');
      });

      test('returns null for unknown ID', () async {
        final label = await repo.getLabel('nonexistent');
        expect(label, isNull);
      });
    });

    group('getTrackingEvents', () {
      test('returns events for known shipment', () async {
        final events = await repo.getTrackingEvents('ship-001');
        expect(events, hasLength(3));
        expect(events.first.status, TrackingStatus.inTransit);
      });

      test('returns empty list for unknown shipment', () async {
        final events = await repo.getTrackingEvents('nonexistent');
        expect(events, isEmpty);
      });

      test('events are ordered newest first', () async {
        final events = await repo.getTrackingEvents('ship-002');
        for (var i = 0; i < events.length - 1; i++) {
          expect(
            events[i].timestamp.isAfter(events[i + 1].timestamp),
            isTrue,
            reason: 'Event $i should be newer than event ${i + 1}',
          );
        }
      });
    });

    group('getParcelShops', () {
      test('returns shops', () async {
        final shops = await repo.getParcelShops('1012RR');
        expect(shops, isNotEmpty);
      });

      test('shops are sorted by distance', () async {
        final shops = await repo.getParcelShops('1012RR');
        for (var i = 0; i < shops.length - 1; i++) {
          expect(
            shops[i].distanceKm <= shops[i + 1].distanceKm,
            isTrue,
            reason: 'Shop $i should be closer than shop ${i + 1}',
          );
        }
      });
    });
  });
}
