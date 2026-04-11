import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/domain/repositories/home_mode_repository.dart';

/// SharedPreferences-backed implementation of [HomeModeRepository].
///
/// Stores the mode as a string under key `'home_mode'`.
/// Defaults to [HomeMode.buyer] when no value is stored.
class SharedPrefsHomeModeRepository implements HomeModeRepository {
  const SharedPrefsHomeModeRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'home_mode';

  @override
  HomeMode getMode() {
    final stored = _prefs.getString(_key);
    if (stored == null) return HomeMode.buyer;
    return HomeMode.fromStorage(stored);
  }

  @override
  Future<void> setMode(HomeMode mode) =>
      _prefs.setString(_key, mode.toStorage());
}
