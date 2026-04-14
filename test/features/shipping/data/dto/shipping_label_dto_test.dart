import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/data/dto/shipping_label_dto.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';

void main() {
  group('ShippingLabelDto', () {
    group('fromJson', () {
      test('parses a complete JSON row', () {
        final label = ShippingLabelDto.fromJson(_validJson());

        expect(label.id, 'ship-001');
        expect(label.transactionId, 'txn-001');
        expect(label.trackingNumber, '3SDEVC1234567');
        expect(label.qrData, '3SDEVC1234567|POSTNL|2521CA');
        expect(label.carrier, ShippingCarrier.postnl);
      });

      test('parses DHL carrier', () {
        final json = _validJson(carrier: 'dhl');
        final label = ShippingLabelDto.fromJson(json);
        expect(label.carrier, ShippingCarrier.dhl);
      });

      test('defaults unknown carrier to postnl', () {
        final json = _validJson(carrier: 'ups');
        final label = ShippingLabelDto.fromJson(json);
        expect(label.carrier, ShippingCarrier.postnl);
      });

      test('parses ship_by_deadline when present', () {
        final json = _validJson();
        json['ship_by_deadline'] = '2026-04-12T00:00:00Z';
        final label = ShippingLabelDto.fromJson(json);
        expect(label.shipByDeadline?.year, 2026);
        expect(label.shipByDeadline?.month, 4);
        expect(label.shipByDeadline?.day, 12);
      });

      test('returns null shipByDeadline when not in JSON', () {
        final label = ShippingLabelDto.fromJson(_validJson());
        expect(label.shipByDeadline, isNull);
      });

      test('throws FormatException on missing required fields', () {
        final json = _validJson()..remove('barcode');
        expect(
          () => ShippingLabelDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromJsonList', () {
      test('parses a list and skips non-maps', () {
        final list = [_validJson(), 'garbage', _validJson(id: 'ship-002')];
        final labels = ShippingLabelDto.fromJsonList(list);
        expect(labels, hasLength(2));
        expect(labels[1].id, 'ship-002');
      });
    });
  });
}

Map<String, dynamic> _validJson({
  String id = 'ship-001',
  String carrier = 'postnl',
}) {
  return {
    'id': id,
    'transaction_id': 'txn-001',
    'barcode': '3SDEVC1234567',
    'qr_data': '3SDEVC1234567|POSTNL|2521CA',
    'carrier': carrier,
    'created_at': '2026-04-08T16:00:00Z',
  };
}
