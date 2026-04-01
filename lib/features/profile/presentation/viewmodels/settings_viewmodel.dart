import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
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
    } on Exception {
      state = state.copyWith(
        notificationPrefs: previous,
        error: 'error.generic',
      );
    }
  }

  Future<void> saveAddress(DutchAddress address) async {
    try {
      await _repo.saveAddress(address);
      final addresses = await _repo.getAddresses();
      state = state.copyWith(addresses: AsyncValue.data(addresses));
    } on Exception {
      state = state.copyWith(error: 'error.generic');
    }
  }

  Future<void> deleteAddress(DutchAddress address) async {
    try {
      await _repo.deleteAddress(address);
      final addresses = await _repo.getAddresses();
      state = state.copyWith(addresses: AsyncValue.data(addresses));
    } on Exception {
      state = state.copyWith(error: 'error.generic');
    }
  }

  /// Allowed hosts for GDPR export download URLs.
  static const _exportAllowedHosts = {'deelmarkt.nl', 'api.deelmarkt.nl'};

  Future<void> exportUserData() async {
    state = state.copyWith(isExporting: true);
    try {
      final url = await _repo.exportUserData();
      // HIGH-1: Validate export URL against allowlist before storing
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          !_exportAllowedHosts.any((host) => uri.host.endsWith(host))) {
        state = state.copyWith(isExporting: false, error: 'error.generic');
        return;
      }
      state = state.copyWith(isExporting: false, exportUrl: url);
    } on Exception {
      state = state.copyWith(isExporting: false, error: 'error.generic');
    }
  }

  /// Delete account — requires password re-authentication (OWASP ASVS §4.2.1).
  Future<void> deleteAccount({required String password}) async {
    state = state.copyWith(isDeleting: true);
    try {
      await _repo.deleteAccount(password: password);
      state = state.copyWith(isDeleting: false);
    } on Exception {
      state = state.copyWith(isDeleting: false, error: 'error.generic');
    }
  }
}

/// Settings viewmodel provider.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref: ref),
);
