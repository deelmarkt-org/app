import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';

/// DTO for converting PostNL/DHL parcel shop API responses to [ParcelShop].
///
/// Note: parcel shops are not stored in the DB — they come from carrier APIs
/// via Edge Functions. This DTO parses the Edge Function response format.
class ParcelShopDto {
  const ParcelShopDto._();

  static ParcelShop fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final address = json['address'];
    final postalCode = json['postal_code'];
    final city = json['city'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];

    if (id is! String ||
        name is! String ||
        address is! String ||
        postalCode is! String ||
        city is! String ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException(
        'ParcelShopDto.fromJson: missing or invalid required fields',
      );
    }

    return ParcelShop(
      id: id,
      name: name,
      address: address,
      postalCode: postalCode,
      city: city,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      carrier: _carrierFromDb((json['carrier'] as String?) ?? 'postnl'),
      openToday: json['open_today'] as String?,
    );
  }

  static List<ParcelShop> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static ParcelShopCarrier _carrierFromDb(String value) => switch (value) {
    'dhl' => ParcelShopCarrier.dhl,
    _ => ParcelShopCarrier.postnl,
  };
}
