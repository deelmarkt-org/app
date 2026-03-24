/// A single tracking event from the shipping carrier (PostNL/DHL).
///
/// Domain layer — no Flutter/Supabase imports.
/// Events are ordered chronologically, newest first.
///
/// Reference: docs/epics/E05-shipping-logistics.md
class TrackingEvent {
  const TrackingEvent({
    required this.id,
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
  });

  final String id;

  /// Carrier-specific status code mapped to our enum.
  final TrackingStatus status;

  /// Human-readable description (localized by the carrier API).
  final String description;

  /// When this event occurred.
  final DateTime timestamp;

  /// Location where the event occurred (e.g. "Amsterdam Sorting Centre").
  final String? location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrackingEvent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Normalized tracking statuses across PostNL and DHL.
enum TrackingStatus {
  /// Label created / QR generated.
  labelCreated,

  /// Package dropped off at service point.
  droppedOff,

  /// Package picked up by carrier.
  pickedUp,

  /// Package in transit / at sorting centre.
  inTransit,

  /// Package out for delivery.
  outForDelivery,

  /// Package delivered to recipient.
  delivered,

  /// Delivery attempt failed.
  deliveryFailed,

  /// Package returned to sender.
  returned;

  /// Whether this is a terminal state.
  bool get isTerminal => switch (this) {
    delivered || returned => true,
    _ => false,
  };
}
