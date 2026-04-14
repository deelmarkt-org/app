import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';

/// DTO for converting Supabase REST JSON to [ShippingLabel].
///
/// Column mapping follows migrations:
/// - 20260324223334_shipping_labels_and_tracking_events.sql
/// - 20260325232025_shipping_label_columns_b25.sql
class ShippingLabelDto {
  const ShippingLabelDto._();

  static ShippingLabel fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final transactionId = json['transaction_id'];
    final barcode = json['barcode'];
    final qrData = json['qr_data'];
    final carrierRaw = json['carrier'];
    final createdAtRaw = json['created_at'];

    if (id is! String ||
        transactionId is! String ||
        barcode is! String ||
        qrData is! String ||
        carrierRaw is! String ||
        createdAtRaw is! String) {
      throw const FormatException(
        'ShippingLabelDto.fromJson: missing or invalid required fields',
      );
    }

    return ShippingLabel(
      id: id,
      transactionId: transactionId,
      qrData: qrData,
      trackingNumber: barcode,
      carrier: _carrierFromDb(carrierRaw),
      destinationPostalCode: '', // Not stored in DB — derived from transaction
      shipByDeadline:
          _parseOptionalDate(json['ship_by_deadline']) ??
          DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }

  static List<ShippingLabel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static ShippingCarrier _carrierFromDb(String value) => switch (value) {
    'postnl' => ShippingCarrier.postnl,
    'dhl' => ShippingCarrier.dhl,
    _ => ShippingCarrier.postnl,
  };

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
