import 'package:equatable/equatable.dart';

/// User notification preferences.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.messages = true,
    this.offers = true,
    this.shippingUpdates = true,
    this.marketing = false,
  });

  /// Receive notifications for new messages.
  final bool messages;

  /// Receive notifications for offers on listings.
  final bool offers;

  /// Receive notifications for shipping status updates.
  final bool shippingUpdates;

  /// Receive marketing and promotional notifications.
  final bool marketing;

  @override
  List<Object?> get props => [messages, offers, shippingUpdates, marketing];

  NotificationPreferences copyWith({
    bool? messages,
    bool? offers,
    bool? shippingUpdates,
    bool? marketing,
  }) {
    return NotificationPreferences(
      messages: messages ?? this.messages,
      offers: offers ?? this.offers,
      shippingUpdates: shippingUpdates ?? this.shippingUpdates,
      marketing: marketing ?? this.marketing,
    );
  }
}
