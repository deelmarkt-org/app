import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

/// DTO for converting Supabase REST JSON to [TrackingEvent].
///
/// Column mapping follows migration 20260324223334_shipping_labels_and_tracking_events.sql.
class TrackingEventDto {
  const TrackingEventDto._();

  static TrackingEvent fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final statusRaw = json['status'];
    final occurredAtRaw = json['occurred_at'];

    if (id is! String || statusRaw is! String || occurredAtRaw is! String) {
      throw const FormatException(
        'TrackingEventDto.fromJson: missing or invalid required fields',
      );
    }

    return TrackingEvent(
      id: id,
      status: _statusFromDb(statusRaw),
      description: (json['description'] as String?) ?? '',
      timestamp: DateTime.tryParse(occurredAtRaw) ?? DateTime.now(),
      location: json['location'] as String?,
    );
  }

  static List<TrackingEvent> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  /// DB stores snake_case status strings; Dart uses camelCase enum.
  static TrackingStatus _statusFromDb(String value) => switch (value) {
    'label_created' => TrackingStatus.labelCreated,
    'dropped_off' => TrackingStatus.droppedOff,
    'picked_up' => TrackingStatus.pickedUp,
    'in_transit' => TrackingStatus.inTransit,
    'out_for_delivery' => TrackingStatus.outForDelivery,
    'delivered' => TrackingStatus.delivered,
    'delivery_failed' => TrackingStatus.deliveryFailed,
    'returned' => TrackingStatus.returned,
    _ => TrackingStatus.inTransit,
  };
}
