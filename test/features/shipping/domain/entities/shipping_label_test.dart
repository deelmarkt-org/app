import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';

void main() {
  group('ShippingLabel', () {
    ShippingLabel label({
      String id = 'ship-001',
      ShippingCarrier carrier = ShippingCarrier.postnl,
    }) {
      return ShippingLabel(
        id: id,
        transactionId: 'txn-001',
        qrData: '3SDEVC1234567|POSTNL|2521CA',
        trackingNumber: '3SDEVC1234567',
        carrier: carrier,
        destinationPostalCode: '2521CA',
        shipByDeadline: DateTime(2026, 4, 12),
        createdAt: DateTime(2026, 4, 8),
      );
    }

    test('equality based on id', () {
      expect(label(), equals(label()));
    });

    test('not equal with different id', () {
      expect(label(), isNot(equals(label(id: 'ship-002'))));
    });

    test('hashCode based on id', () {
      expect(label().hashCode, equals(label().hashCode));
    });

    test('postnl carrier', () {
      expect(label().carrier, ShippingCarrier.postnl);
    });

    test('dhl carrier', () {
      expect(label(carrier: ShippingCarrier.dhl).carrier, ShippingCarrier.dhl);
    });

    test('destinationPostalCode is accessible', () {
      expect(label().destinationPostalCode, '2521CA');
    });
  });
}
