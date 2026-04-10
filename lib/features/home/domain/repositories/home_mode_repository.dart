import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';

/// Repository for persisting the user's home screen mode preference.
///
/// Implementation: [SharedPrefsHomeModeRepository] (SharedPreferences).
/// Mode is a client-side UI preference — not stored in the database.
abstract class HomeModeRepository {
  /// Get the current mode preference. Returns [HomeMode.buyer] if not set.
  HomeMode getMode();

  /// Persist the selected mode.
  Future<void> setMode(HomeMode mode);
}
