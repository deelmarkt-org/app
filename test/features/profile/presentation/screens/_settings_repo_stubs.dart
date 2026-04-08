import 'dart:async';

import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

// ── Test data ────────────────────────────────────────────────────────────────

final testUser = UserEntity(
  id: 'user-001',
  displayName: 'Jan de Vries',
  email: 'jan@example.com',
  phone: '+31 6 1234 5678',
  kycLevel: KycLevel.level1,
  location: 'Amsterdam',
  badges: const [BadgeType.emailVerified],
  averageRating: 4.7,
  reviewCount: 23,
  responseTimeMinutes: 15,
  createdAt: DateTime(2025, 6),
);

const testAddresses = [
  DutchAddress(
    postcode: '1012 AB',
    houseNumber: '42',
    street: 'Damstraat',
    city: 'Amsterdam',
  ),
];

const testPrefs = NotificationPreferences(offers: false);

// ── Settings repository stubs ─────────────────────────────────────────────────

/// Settings repository that returns data instantly for widget tests.
class InstantSettingsRepository implements SettingsRepository {
  const InstantSettingsRepository();

  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      testPrefs;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => testAddresses;

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'https://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Settings repository where addresses never finish loading.
class HangingAddressesSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      testPrefs;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() =>
      Completer<List<DutchAddress>>().future;

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'https://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Settings repository where addresses throw.
class ErrorAddressesSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      testPrefs;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() => throw Exception('Network error');

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'https://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Settings repository where notifications never finish loading.
class HangingNotificationsSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() =>
      Completer<NotificationPreferences>().future;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => testAddresses;

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'https://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Settings repository where notifications throw.
class ErrorNotificationsSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() =>
      throw Exception('Network error');

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => testAddresses;

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'https://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Settings repository for exporting state test.
class ExportingSettingsRepository extends InstantSettingsRepository {
  @override
  Future<String> exportUserData() => Completer<String>().future;
}

/// Settings repository for deleting state test.
class DeletingSettingsRepository extends InstantSettingsRepository {
  @override
  Future<void> deleteAccount({required String password}) =>
      Completer<void>().future;
}
