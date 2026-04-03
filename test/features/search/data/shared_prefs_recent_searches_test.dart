import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/search/data/shared_prefs_recent_searches_repo.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPrefsRecentSearchesRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SharedPrefsRecentSearchesRepo(prefs);
  });

  group('SharedPrefsRecentSearchesRepo', () {
    test('getAll returns empty list initially', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('add stores a query', () async {
      await repo.add('fiets');
      expect(await repo.getAll(), ['fiets']);
    });

    test('add prepends newest first', () async {
      await repo.add('fiets');
      await repo.add('auto');
      expect(await repo.getAll(), ['auto', 'fiets']);
    });

    test('add deduplicates and moves to front', () async {
      await repo.add('fiets');
      await repo.add('auto');
      await repo.add('fiets');
      expect(await repo.getAll(), ['fiets', 'auto']);
    });

    test('add trims to 10 entries', () async {
      for (var i = 0; i < 12; i++) {
        await repo.add('query-$i');
      }
      final all = await repo.getAll();
      expect(all.length, 10);
      expect(all.first, 'query-11');
    });

    test('add ignores empty/whitespace queries', () async {
      await repo.add('');
      await repo.add('   ');
      expect(await repo.getAll(), isEmpty);
    });

    test('remove deletes a specific query', () async {
      await repo.add('fiets');
      await repo.add('auto');
      await repo.remove('fiets');
      expect(await repo.getAll(), ['auto']);
    });

    test('clear removes all queries', () async {
      await repo.add('fiets');
      await repo.add('auto');
      await repo.clear();
      expect(await repo.getAll(), isEmpty);
    });
  });
}
