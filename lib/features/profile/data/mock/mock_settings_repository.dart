import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

/// Mock settings repository — returns static data for development.
///
/// All methods include a 500ms delay to simulate network latency.
/// Guarded by [kReleaseMode] — asserts in release builds.
class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository() {
    assert(
      !kReleaseMode,
      'MockSettingsRepository must not be used in release builds',
    );
  }

  NotificationPreferences _prefs = const NotificationPreferences();

  final List<DutchAddress> _addresses = [
    const DutchAddress(
      postcode: '1012 AB',
      houseNumber: '42',
      street: 'Damstraat',
      city: 'Amsterdam',
    ),
    const DutchAddress(
      postcode: '3011 HE',
      houseNumber: '15',
      addition: 'B',
      street: 'Coolsingel',
      city: 'Rotterdam',
    ),
  ];

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _prefs;
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _prefs = prefs;
    return _prefs;
  }

  @override
  Future<List<DutchAddress>> getAddresses() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_addresses);
  }

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final index = _addresses.indexWhere(
      (a) =>
          a.postcode == address.postcode &&
          a.houseNumber == address.houseNumber,
    );
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    return address;
  }

  @override
  Future<void> deleteAddress(DutchAddress address) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _addresses.removeWhere(
      (a) =>
          a.postcode == address.postcode &&
          a.houseNumber == address.houseNumber,
    );
  }

  @override
  Future<String> exportUserData() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return 'https://deelmarkt.nl/export/mock-data-export.zip';
  }

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
