import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

/// Settings screen state — independent async values per section.
class SettingsState {
  const SettingsState({
    this.notificationPrefs = const AsyncValue.loading(),
    this.addresses = const AsyncValue.loading(),
    this.isExporting = false,
    this.isDeleting = false,
    this.exportUrl,
    this.error,
  });

  final AsyncValue<NotificationPreferences> notificationPrefs;
  final AsyncValue<List<DutchAddress>> addresses;
  final bool isExporting;
  final bool isDeleting;
  final String? exportUrl;
  final String? error;

  SettingsState copyWith({
    AsyncValue<NotificationPreferences>? notificationPrefs,
    AsyncValue<List<DutchAddress>>? addresses,
    bool? isExporting,
    bool? isDeleting,
    String? exportUrl,
    String? error,
  }) {
    return SettingsState(
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      addresses: addresses ?? this.addresses,
      isExporting: isExporting ?? this.isExporting,
      isDeleting: isDeleting ?? this.isDeleting,
      exportUrl: exportUrl ?? this.exportUrl,
      error: error,
    );
  }
}

/// ViewModel for the settings screen.
///
/// Notification toggles use optimistic updates: the UI flips immediately
/// and rolls back on failure. Export and delete show loading states.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier({required Ref ref})
    : _ref = ref,
      super(const SettingsState()) {
    load();
  }

  final Ref _ref;

  SettingsRepository get _repo => _ref.read(settingsRepositoryProvider);

  Future<void> load() async {
    final prefsFuture = AsyncValue.guard(
      () => _repo.getNotificationPreferences(),
    );
    final addressesFuture = AsyncValue.guard(() => _repo.getAddresses());

    final results = await Future.wait([prefsFuture, addressesFuture]);
    state = state.copyWith(
      notificationPrefs: results[0] as AsyncValue<NotificationPreferences>,
      addresses: results[1] as AsyncValue<List<DutchAddress>>,
    );
  }

  /// Optimistic notification toggle — flips immediately, rolls back on error.
  Future<void> updateNotificationPrefs(NotificationPreferences prefs) async {
    final previous = state.notificationPrefs;
    state = state.copyWith(notificationPrefs: AsyncValue.data(prefs));

    try {
      await _repo.updateNotificationPreferences(prefs);
    } catch (e, st) {
      state = state.copyWith(notificationPrefs: previous, error: e.toString());
      // Re-throw so Riverpod error listeners can react
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> saveAddress(DutchAddress address) async {
    try {
      await _repo.saveAddress(address);
      final addresses = await _repo.getAddresses();
      state = state.copyWith(addresses: AsyncValue.data(addresses));
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteAddress(DutchAddress address) async {
    try {
      await _repo.deleteAddress(address);
      final addresses = await _repo.getAddresses();
      state = state.copyWith(addresses: AsyncValue.data(addresses));
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> exportUserData() async {
    state = state.copyWith(isExporting: true);
    try {
      final url = await _repo.exportUserData();
      state = state.copyWith(isExporting: false, exportUrl: url);
    } catch (e, st) {
      state = state.copyWith(isExporting: false, error: e.toString());
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isDeleting: true);
    try {
      await _repo.deleteAccount();
      state = state.copyWith(isDeleting: false);
    } catch (e, st) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      Error.throwWithStackTrace(e, st);
    }
  }
}

/// Settings repository provider — mock or real.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockSettingsRepository();
  // TODO(reso): Add SupabaseSettingsRepository when settings table is ready
  return MockSettingsRepository();
});

/// Settings viewmodel provider.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref: ref),
);
