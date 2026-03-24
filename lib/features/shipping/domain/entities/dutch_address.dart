/// Dutch postal address with postcode auto-fill support.
///
/// Domain layer — no Flutter/Supabase imports.
/// Postcode format: 4 digits + space + 2 letters (e.g. "1012 AB").
///
/// Reference: docs/epics/E05-shipping-logistics.md §Dutch Address
class DutchAddress {
  const DutchAddress({
    required this.postcode,
    required this.houseNumber,
    required this.street,
    required this.city,
    this.addition,
    this.latitude,
    this.longitude,
  });

  /// Dutch postcode in 4+2 format (e.g. "1012 AB").
  final String postcode;

  /// House number (e.g. "42").
  final String houseNumber;

  /// Optional addition (toevoeging, e.g. "A", "II").
  final String? addition;

  /// Street name — auto-filled from PostNL postcode API.
  final String street;

  /// City name — auto-filled from PostNL postcode API.
  final String city;

  final double? latitude;
  final double? longitude;

  /// Full formatted address.
  String get formatted =>
      '$street $houseNumber${addition != null ? ' $addition' : ''}, $postcode $city';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DutchAddress &&
          postcode == other.postcode &&
          houseNumber == other.houseNumber &&
          addition == other.addition;

  @override
  int get hashCode => Object.hash(postcode, houseNumber, addition);
}
