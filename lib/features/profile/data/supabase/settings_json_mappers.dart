import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';

/// JSON → [NotificationPreferences] mapper for Supabase responses.
NotificationPreferences notificationPrefsFromJson(Map<String, dynamic> json) {
  return NotificationPreferences(
    messages: json['messages'] as bool? ?? true,
    offers: json['offers'] as bool? ?? true,
    shippingUpdates: json['shipping_updates'] as bool? ?? true,
    marketing: json['marketing'] as bool? ?? false,
  );
}

/// JSON → [DutchAddress] mapper for Supabase responses.
DutchAddress dutchAddressFromJson(Map<String, dynamic> json) {
  return DutchAddress(
    postcode: json['postcode'] as String,
    houseNumber: json['house_number'] as String,
    addition: json['addition'] as String?,
    street: json['street'] as String,
    city: json['city'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}
