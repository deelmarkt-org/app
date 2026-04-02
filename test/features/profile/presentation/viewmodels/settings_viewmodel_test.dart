import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/settings_viewmodel.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

/// A failing settings repository that throws on every method.
/// Used to test error handling and optimistic rollback.
class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() =>
      throw Exception('network error');

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) => throw Exception('network error');

  @override
  Future<List<DutchAddress>> getAddresses() => throw Exception('network error');

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) =>
      throw Exception('network error');

  @override
  Future<void> deleteAddress(DutchAddress address) =>
      throw Exception('network error');

  @override
  Future<String> exportUserData() => throw Exception('network error');

  @override
  Future<void> deleteAccount({required String password}) =>
      throw Exception('network error');
}

/// Creates a container with mock data, subscribes to keep the provider alive,
/// and waits for the initial load to complete.
Future<ProviderContainer> _loadedContainer({
  SettingsRepository? repoOverride,
}) async {
  final overrides = <Override>[
    useMockDataProvider.overrideWithValue(true),
    if (repoOverride != null)
      settingsRepositoryProvider.overrideWithValue(repoOverride),
  ];
  final container = ProviderContainer(overrides: overrides)
    ..listen(settingsNotifierProvider, (_, _) {});
  // Mock repos use 500ms delays — wait for initial load.
  await Future<void>.delayed(const Duration(milliseconds: 600));
  return container;
}

void main() {
  group('SettingsNotifier', () {
    test('load() populates notification preferences', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);
      expect(state.notificationPrefs.hasValue, isTrue);
    });

    test('load() populates addresses', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);
      expect(state.addresses.hasValue, isTrue);
      expect(state.addresses.requireValue, isNotEmpty);
    });

    test('updateNotificationPrefs() optimistically updates state', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      const newPrefs = NotificationPreferences(
        messages: false,
        offers: false,
        marketing: true,
      );

      // Fire the update (don't await — check optimistic state immediately).
      final future = container
          .read(settingsNotifierProvider.notifier)
          .updateNotificationPrefs(newPrefs);

      // Optimistic: state should reflect new prefs immediately.
      final state = container.read(settingsNotifierProvider);
      expect(state.notificationPrefs.requireValue, equals(newPrefs));

      await future;
    });

    test('updateNotificationPrefs() rolls back on failure', () async {
      // Use a repo that loads successfully but fails on update.
      final partialFailRepo = _UpdateFailingSettingsRepository();
      final container = await _loadedContainer(repoOverride: partialFailRepo);
      addTearDown(container.dispose);

      final before =
          container
              .read(settingsNotifierProvider)
              .notificationPrefs
              .requireValue;

      const newPrefs = NotificationPreferences(
        messages: false,
        offers: false,
        shippingUpdates: false,
        marketing: true,
      );

      await container
          .read(settingsNotifierProvider.notifier)
          .updateNotificationPrefs(newPrefs);

      // Should have rolled back to previous value.
      final after = container.read(settingsNotifierProvider);
      expect(after.notificationPrefs.requireValue, equals(before));
      expect(after.error, equals('error.generic'));
    });

    test('saveAddress() adds a new address and refreshes list', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final initialCount =
          container
              .read(settingsNotifierProvider)
              .addresses
              .requireValue
              .length;

      const newAddress = DutchAddress(
        postcode: '2511 DP',
        houseNumber: '1',
        street: 'Binnenhof',
        city: 'Den Haag',
      );

      await container
          .read(settingsNotifierProvider.notifier)
          .saveAddress(newAddress);

      final state = container.read(settingsNotifierProvider);
      expect(state.addresses.requireValue.length, equals(initialCount + 1));
    });

    test('deleteAddress() removes address and refreshes list', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      final addresses =
          container.read(settingsNotifierProvider).addresses.requireValue;
      final initialCount = addresses.length;
      final toDelete = addresses.first;

      await container
          .read(settingsNotifierProvider.notifier)
          .deleteAddress(toDelete);

      final state = container.read(settingsNotifierProvider);
      expect(state.addresses.requireValue.length, equals(initialCount - 1));
    });

    test('exportUserData() sets exportUrl for valid URL', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container.read(settingsNotifierProvider.notifier).exportUserData();

      final state = container.read(settingsNotifierProvider);
      expect(state.isExporting, isFalse);
      expect(state.exportUrl, isNotNull);
      expect(state.exportUrl, contains('deelmarkt.nl'));
    });

    test('exportUserData() rejects URL with invalid host', () async {
      final badUrlRepo = _BadUrlSettingsRepository();
      final container = await _loadedContainer(repoOverride: badUrlRepo);
      addTearDown(container.dispose);

      await container.read(settingsNotifierProvider.notifier).exportUserData();

      final state = container.read(settingsNotifierProvider);
      expect(state.isExporting, isFalse);
      expect(state.exportUrl, isNull);
      expect(state.error, equals('error.generic'));
    });

    test('exportUserData() rejects non-HTTPS URL', () async {
      final httpRepo = _HttpUrlSettingsRepository();
      final container = await _loadedContainer(repoOverride: httpRepo);
      addTearDown(container.dispose);

      await container.read(settingsNotifierProvider.notifier).exportUserData();

      final state = container.read(settingsNotifierProvider);
      expect(state.exportUrl, isNull);
      expect(state.error, equals('error.generic'));
    });

    test('exportUserData() sets error on failure', () async {
      final failRepo = _ExportFailingSettingsRepository();
      final container = await _loadedContainer(repoOverride: failRepo);
      addTearDown(container.dispose);

      await container.read(settingsNotifierProvider.notifier).exportUserData();

      final state = container.read(settingsNotifierProvider);
      expect(state.isExporting, isFalse);
      expect(state.error, equals('error.generic'));
    });

    test('deleteAccount() completes without error', () async {
      final container = await _loadedContainer();
      addTearDown(container.dispose);

      await container
          .read(settingsNotifierProvider.notifier)
          .deleteAccount(password: 'test123'); // pragma: allowlist secret

      final state = container.read(settingsNotifierProvider);
      expect(state.isDeleting, isFalse);
      expect(state.error, isNull);
    });

    test('deleteAccount() sets error on failure', () async {
      final container = await _loadedContainer(
        repoOverride: _FailingSettingsRepository(),
      );
      addTearDown(container.dispose);

      // load() will fail, but deleteAccount should still set error.
      await container
          .read(settingsNotifierProvider.notifier)
          .deleteAccount(password: 'wrong'); // pragma: allowlist secret

      final state = container.read(settingsNotifierProvider);
      expect(state.isDeleting, isFalse);
      expect(state.error, equals('error.generic'));
    });
  });

  group('SettingsState', () {
    test('copyWith returns new instance with updated fields', () {
      const state = SettingsState();
      final updated = state.copyWith(isExporting: true, exportUrl: 'test');
      expect(updated.isExporting, isTrue);
      expect(updated.exportUrl, equals('test'));
      expect(updated.isDeleting, isFalse);
    });

    test('copyWith preserves existing values when not overridden', () {
      const state = SettingsState(isExporting: true);
      final updated = state.copyWith(isDeleting: true);
      expect(updated.isExporting, isTrue);
      expect(updated.isDeleting, isTrue);
    });

    test('error is cleared when set to null via copyWith', () {
      const state = SettingsState(error: 'some error');
      final updated = state.copyWith();
      // error parameter defaults to null, which clears it.
      expect(updated.error, isNull);
    });
  });
}

/// Repository that loads successfully but fails on update.
class _UpdateFailingSettingsRepository implements SettingsRepository {
  final _prefs = const NotificationPreferences();
  final _addresses = <DutchAddress>[
    const DutchAddress(
      postcode: '1012 AB',
      houseNumber: '42',
      street: 'Damstraat',
      city: 'Amsterdam',
    ),
  ];

  @override
  Future<NotificationPreferences> getNotificationPreferences() async => _prefs;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) => throw Exception('update failed');

  @override
  Future<List<DutchAddress>> getAddresses() async => _addresses;

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) =>
      throw Exception('save failed');

  @override
  Future<void> deleteAddress(DutchAddress address) =>
      throw Exception('delete failed');

  @override
  Future<String> exportUserData() => throw Exception('export failed');

  @override
  Future<void> deleteAccount({required String password}) =>
      throw Exception('delete failed');
}

/// Repository that returns an invalid export URL (wrong host).
class _BadUrlSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => [];

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async => 'https://evil.com/steal-data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Repository that returns an HTTP (non-HTTPS) export URL.
class _HttpUrlSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => [];

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() async =>
      'http://deelmarkt.nl/export/data.zip';

  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Repository that throws on exportUserData.
class _ExportFailingSettingsRepository implements SettingsRepository {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async => prefs;

  @override
  Future<List<DutchAddress>> getAddresses() async => [];

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async => address;

  @override
  Future<void> deleteAddress(DutchAddress address) async {}

  @override
  Future<String> exportUserData() => throw Exception('export failed');

  @override
  Future<void> deleteAccount({required String password}) async {}
}
