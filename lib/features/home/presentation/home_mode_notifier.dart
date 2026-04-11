import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';

part 'home_mode_notifier.g.dart';

/// Manages the buyer/seller mode toggle on the home screen.
///
/// Reads initial value from SharedPreferences on build.
/// Persists changes back to SharedPreferences on toggle.
/// keepAlive: mode should survive widget rebuilds.
@Riverpod(keepAlive: true)
class HomeModeNotifier extends _$HomeModeNotifier {
  @override
  HomeMode build() {
    final repo = ref.watch(homeModeRepositoryProvider);
    return repo.getMode();
  }

  /// Toggle between buyer and seller mode.
  void toggle() {
    final repo = ref.read(homeModeRepositoryProvider);
    final next = state == HomeMode.buyer ? HomeMode.seller : HomeMode.buyer;
    state = next;
    repo.setMode(next);
  }

  /// Set a specific mode.
  void setMode(HomeMode mode) {
    if (state == mode) return;
    final repo = ref.read(homeModeRepositoryProvider);
    state = mode;
    repo.setMode(mode);
  }
}
