/// A PostNL or DHL service point for parcel drop-off/pickup.
///
/// Domain layer — no Flutter/Supabase imports.
///
/// Reference: docs/epics/E05-shipping-logistics.md §ParcelShop Selector
class ParcelShop {
  const ParcelShop({
    required this.id,
    required this.name,
    required this.address,
    required this.postalCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.carrier,
    this.openToday,
  });

  final String id;
  final String name;
  final String address;
  final String postalCode;
  final String city;
  final double latitude;
  final double longitude;

  /// Distance from user's location in km.
  final double distanceKm;

  /// Carrier: 'postnl' or 'dhl'.
  final ParcelShopCarrier carrier;

  /// Today's opening hours (e.g. "08:00–20:00") or null if closed.
  final String? openToday;

  /// Full address line.
  String get fullAddress => '$address, $postalCode $city';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ParcelShop && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Carrier type for parcel shops.
enum ParcelShopCarrier { postnl, dhl }
