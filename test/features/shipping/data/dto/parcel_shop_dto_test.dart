import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/data/dto/parcel_shop_dto.dart';
import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';

void main() {
  group('ParcelShopDto', () {
    group('fromJson', () {
      test('parses a complete JSON row', () {
        final shop = ParcelShopDto.fromJson(_validJson());

        expect(shop.id, 'ps-001');
        expect(shop.name, 'PostNL Punt Albert Heijn');
        expect(shop.postalCode, '1012RR');
        expect(shop.city, 'Amsterdam');
        expect(shop.latitude, 52.3738);
        expect(shop.longitude, 4.891);
        expect(shop.distanceKm, 0.3);
        expect(shop.carrier, ParcelShopCarrier.postnl);
        expect(shop.openToday, '08:00–22:00');
      });

      test('parses DHL carrier', () {
        final json = _validJson(carrier: 'dhl');
        final shop = ParcelShopDto.fromJson(json);
        expect(shop.carrier, ParcelShopCarrier.dhl);
      });

      test('defaults missing distance to 0', () {
        final json = _validJson()..remove('distance_km');
        final shop = ParcelShopDto.fromJson(json);
        expect(shop.distanceKm, 0);
      });

      test('handles null open_today', () {
        final json = _validJson()..remove('open_today');
        final shop = ParcelShopDto.fromJson(json);
        expect(shop.openToday, isNull);
      });

      test('throws FormatException on missing required fields', () {
        final json = _validJson()..remove('name');
        expect(
          () => ParcelShopDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromJsonList', () {
      test('parses a list and skips non-maps', () {
        final list = [_validJson(), 42, _validJson(id: 'ps-002')];
        final shops = ParcelShopDto.fromJsonList(list);
        expect(shops, hasLength(2));
      });
    });
  });
}

Map<String, dynamic> _validJson({
  String id = 'ps-001',
  String carrier = 'postnl',
}) {
  return {
    'id': id,
    'name': 'PostNL Punt Albert Heijn',
    'address': 'Nieuwezijds Voorburgwal 226',
    'postal_code': '1012RR',
    'city': 'Amsterdam',
    'latitude': 52.3738,
    'longitude': 4.891,
    'distance_km': 0.3,
    'carrier': carrier,
    'open_today': '08:00–22:00',
  };
}
