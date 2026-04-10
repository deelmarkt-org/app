/// Represents a shipping label with QR code data for label-free shipping.
///
/// Domain layer — no Flutter/Supabase imports.
/// QR data is generated server-side via PostNL/DHL API (B-25/B-26).
///
/// Reference: docs/epics/E05-shipping-logistics.md
class ShippingLabel {
  const ShippingLabel({
    required this.id,
    required this.transactionId,
    required this.qrData,
    required this.trackingNumber,
    required this.carrier,
    required this.destinationPostalCode,
    required this.shipByDeadline,
    required this.createdAt,
  });

  final String id;
  final String transactionId;

  /// Encoded QR code data (scanned at PostNL/DHL service point).
  final String qrData;

  /// Carrier tracking number (e.g. '3SDEVC1234567').
  final String trackingNumber;

  /// Shipping carrier: 'postnl' or 'dhl'.
  final ShippingCarrier carrier;

  /// Destination postal code for parcel shop lookup.
  final String destinationPostalCode;

  /// Seller must ship by this deadline.
  final DateTime shipByDeadline;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShippingLabel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Supported shipping carriers.
enum ShippingCarrier { postnl, dhl }
