import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

/// Settings repository interface — domain layer.
abstract class SettingsRepository {
  /// Get current notification preferences.
  Future<NotificationPreferences> getNotificationPreferences();

  /// Update notification preferences.
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  );

  /// Get all saved addresses.
  Future<List<DutchAddress>> getAddresses();

  /// Save (add or update) an address.
  Future<DutchAddress> saveAddress(DutchAddress address);

  /// Delete an address by postcode + house number.
  Future<void> deleteAddress(DutchAddress address);

  /// Request GDPR data export. Returns a download URL.
  Future<String> exportUserData();

  /// Permanently delete user account.
  ///
  /// Requires [password] for re-authentication before deletion
  /// (OWASP ASVS L2 §4.2.1). Consider 30-day soft-delete grace period
  /// before permanent deletion (Dutch market expectation).
  Future<void> deleteAccount({required String password});
}
