import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/domain/repositories/shipping_repository.dart';

/// In-memory mock for development when shipping tables aren't ready.
///
/// Returns hardcoded shipping data after a simulated network delay.
/// Toggle via provider override in dev builds (ADR-MOCK-SWAP).
class MockShippingRepository implements ShippingRepository {
  MockShippingRepository() {
    if (kReleaseMode) {
      throw StateError(
        'MockShippingRepository cannot be used in release builds',
      );
    }
  }

  static const _idPostnl = 'ship-001';
  static const _idDhl = 'ship-002';
  static const _amsterdam = 'Amsterdam';

  static final _labels = <String, ShippingLabel>{
    _idPostnl: ShippingLabel(
      id: _idPostnl,
      transactionId: 'txn-shipped',
      qrData: '3SDEVC1234567|POSTNL|2521CA',
      trackingNumber: '3SDEVC1234567',
      carrier: ShippingCarrier.postnl,
      destinationPostalCode: '2521CA',
      shipByDeadline: DateTime(2026, 4, 12),
      createdAt: DateTime(2026, 4, 8),
    ),
    _idDhl: ShippingLabel(
      id: _idDhl,
      transactionId: 'txn-delivered',
      qrData: 'JVGL0987654321|DHL|1015AA',
      trackingNumber: 'JVGL0987654321',
      carrier: ShippingCarrier.dhl,
      destinationPostalCode: '1015AA',
      shipByDeadline: DateTime(2026, 4, 10),
      createdAt: DateTime(2026, 4, 6),
    ),
  };

  static final _events = <String, List<TrackingEvent>>{
    _idPostnl: [
      TrackingEvent(
        id: 'evt-003',
        status: TrackingStatus.inTransit,
        description: 'Pakket in sorteercentrum Amsterdam',
        timestamp: DateTime(2026, 4, 9, 14, 30),
        location: 'Amsterdam Sorteercentrum',
      ),
      TrackingEvent(
        id: 'evt-002',
        status: TrackingStatus.droppedOff,
        description: 'Pakket afgeleverd bij servicepunt',
        timestamp: DateTime(2026, 4, 9, 10, 15),
        location: 'PostNL Punt Albert Heijn Centrum',
      ),
      TrackingEvent(
        id: 'evt-001',
        status: TrackingStatus.labelCreated,
        description: 'Verzendlabel aangemaakt',
        timestamp: DateTime(2026, 4, 8, 16),
      ),
    ],
    _idDhl: [
      TrackingEvent(
        id: 'evt-006',
        status: TrackingStatus.delivered,
        description: 'Pakket bezorgd',
        timestamp: DateTime(2026, 4, 9, 11),
        location: _amsterdam,
      ),
      TrackingEvent(
        id: 'evt-005',
        status: TrackingStatus.outForDelivery,
        description: 'Pakket onderweg naar bezorgadres',
        timestamp: DateTime(2026, 4, 9, 8, 30),
        location: _amsterdam,
      ),
      TrackingEvent(
        id: 'evt-004',
        status: TrackingStatus.pickedUp,
        description: 'Pakket opgehaald bij servicepunt',
        timestamp: DateTime(2026, 4, 8, 18),
        location: 'DHL ServicePoint Haarlem',
      ),
    ],
  };

  static final _parcelShops = <ParcelShop>[
    const ParcelShop(
      id: 'ps-001',
      name: 'PostNL Punt Albert Heijn Centrum',
      address: 'Nieuwezijds Voorburgwal 226',
      postalCode: '1012RR',
      city: _amsterdam,
      latitude: 52.3738,
      longitude: 4.8910,
      distanceKm: 0.3,
      carrier: ParcelShopCarrier.postnl,
      openToday: '08:00–22:00',
    ),
    const ParcelShop(
      id: 'ps-002',
      name: 'PostNL Punt Bruna Kalverstraat',
      address: 'Kalverstraat 115',
      postalCode: '1012PA',
      city: _amsterdam,
      latitude: 52.3712,
      longitude: 4.8924,
      distanceKm: 0.5,
      carrier: ParcelShopCarrier.postnl,
      openToday: '09:00–18:00',
    ),
    const ParcelShop(
      id: 'ps-003',
      name: 'DHL ServicePoint Hema Damrak',
      address: 'Damrak 79',
      postalCode: '1012LN',
      city: _amsterdam,
      latitude: 52.3752,
      longitude: 4.8952,
      distanceKm: 0.7,
      carrier: ParcelShopCarrier.dhl,
      openToday: '09:00–21:00',
    ),
  ];

  @override
  Future<ShippingLabel?> getLabel(String shippingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _labels[shippingId];
  }

  @override
  Future<List<TrackingEvent>> getTrackingEvents(String shippingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _events[shippingId] ?? [];
  }

  @override
  Future<List<ParcelShop>> getParcelShops(String postalCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _parcelShops;
  }
}
