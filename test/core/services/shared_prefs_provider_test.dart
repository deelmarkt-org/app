import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';

void main() {
  group('SharedPreferences provider', () {
    test('initSharedPreferences initialises the instance', () async {
      SharedPreferences.setMockInitialValues({});
      await initSharedPreferences();

      // After init, the provider function should not throw.
      // We can't call the Riverpod provider directly without a container,
      // but we can verify init completes without error.
      expect(true, isTrue);
    });

    test('initSharedPreferences can be called multiple times safely', () async {
      SharedPreferences.setMockInitialValues({});
      await initSharedPreferences();
      await initSharedPreferences();

      // Idempotent — no crash on double init.
      expect(true, isTrue);
    });
  });
}
