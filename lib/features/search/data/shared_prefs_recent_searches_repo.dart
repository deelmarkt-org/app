import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/search/domain/recent_searches_repository.dart';

/// SharedPreferences-backed recent searches storage.
///
/// Stores up to [_maxEntries] queries as a string list under [_key].
/// Most recent query first (LIFO).
class SharedPrefsRecentSearchesRepo implements RecentSearchesRepository {
  const SharedPrefsRecentSearchesRepo(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'recent_searches';
  static const _maxEntries = 10;

  @override
  Future<List<String>> getAll() async {
    return _prefs.getStringList(_key) ?? [];
  }

  @override
  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = await getAll();
    current
      ..remove(trimmed)
      ..insert(0, trimmed);
    if (current.length > _maxEntries) {
      current.removeRange(_maxEntries, current.length);
    }
    await _prefs.setStringList(_key, current);
  }

  @override
  Future<void> remove(String query) async {
    final current = await getAll();
    current.remove(query);
    await _prefs.setStringList(_key, current);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
