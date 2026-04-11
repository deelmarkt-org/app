import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/data/shared_prefs_home_mode_repository.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';

void main() {
  group('SharedPrefsHomeModeRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('getMode returns buyer when no value stored', () {
      final repo = SharedPrefsHomeModeRepository(prefs);
      expect(repo.getMode(), HomeMode.buyer);
    });

    test('setMode persists seller and getMode returns it', () async {
      final repo = SharedPrefsHomeModeRepository(prefs);

      await repo.setMode(HomeMode.seller);

      expect(repo.getMode(), HomeMode.seller);
    });

    test('setMode persists buyer and getMode returns it', () async {
      final repo = SharedPrefsHomeModeRepository(prefs);

      await repo.setMode(HomeMode.seller);
      await repo.setMode(HomeMode.buyer);

      expect(repo.getMode(), HomeMode.buyer);
    });

    test('getMode defaults to buyer for unknown stored values', () async {
      SharedPreferences.setMockInitialValues({'home_mode': 'invalid'});
      final prefsWithInvalid = await SharedPreferences.getInstance();
      final repo = SharedPrefsHomeModeRepository(prefsWithInvalid);

      expect(repo.getMode(), HomeMode.buyer);
    });
  });
}
