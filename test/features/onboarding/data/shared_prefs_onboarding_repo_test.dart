import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/onboarding/data/shared_prefs_onboarding_repo.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPrefsOnboardingRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SharedPrefsOnboardingRepo(prefs);
  });

  group('SharedPrefsOnboardingRepo', () {
    test('isComplete returns false when key does not exist', () async {
      expect(await repo.isComplete(), isFalse);
    });

    test('complete sets flag and isComplete returns true', () async {
      await repo.complete();
      expect(await repo.isComplete(), isTrue);
    });

    test('isComplete returns true when flag already set', () async {
      await prefs.setBool('onboarding_complete', true);
      expect(await repo.isComplete(), isTrue);
    });

    test('new instance reads persisted flag', () async {
      await repo.complete();
      final freshRepo = SharedPrefsOnboardingRepo(prefs);
      expect(await freshRepo.isComplete(), isTrue);
    });
  });
}
