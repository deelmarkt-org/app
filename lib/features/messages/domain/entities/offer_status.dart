/// Lifecycle status for offer-type messages.
///
/// Only non-null when [MessageType.offer]; all other message types have null.
/// Transitions: pending → accepted | declined (terminal states, no reversal).
enum OfferStatus {
  pending,
  accepted,
  declined;

  /// Maps DB snake_case value to [OfferStatus]. Returns null for unknown values.
  static OfferStatus? fromDb(String? value) => switch (value) {
    'pending' => OfferStatus.pending,
    'accepted' => OfferStatus.accepted,
    'declined' => OfferStatus.declined,
    _ => null,
  };

  String toDb() => switch (this) {
    OfferStatus.pending => 'pending',
    OfferStatus.accepted => 'accepted',
    OfferStatus.declined => 'declined',
  };
}
