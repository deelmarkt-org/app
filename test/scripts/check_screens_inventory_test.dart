import 'package:flutter_test/flutter_test.dart';

import '../../scripts/check_screens_inventory.dart' as script;

void main() {
  group('check_screens_inventory.evaluate', () {
    final fixedNow = DateTime(2026, 04, 25);

    test('OK when document is fresh (< 60 days)', () {
      const contents = '**Last updated:** 2026-04-01';
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 0);
      expect(result.message, startsWith('OK'));
      expect(result.daysSinceUpdate, lessThan(script.warnDays));
    });

    test('WARN when document is in the warning band (60–119 days)', () {
      const contents = '**Last updated:** 2026-02-01';
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 0, reason: 'WARN must not block CI');
      expect(result.message, startsWith('WARN'));
      expect(result.daysSinceUpdate, greaterThanOrEqualTo(script.warnDays));
      expect(result.daysSinceUpdate, lessThan(script.failDays));
    });

    test('ERROR when document is rotten (>= 120 days)', () {
      const contents = '**Last updated:** 2025-12-01';
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 1);
      expect(result.message, startsWith('ERROR'));
      expect(result.daysSinceUpdate, greaterThanOrEqualTo(script.failDays));
    });

    test('ERROR when header is missing', () {
      const contents = '# Some doc without the expected header';
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 1);
      expect(result.message, contains('missing'));
      expect(result.daysSinceUpdate, isNull);
    });

    test('boundary: exactly 60 days → WARN, not OK', () {
      const contents =
          '**Last updated:** 2026-02-24'; // 60 days before 2026-04-25
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 0);
      expect(result.message, startsWith('WARN'));
      expect(result.daysSinceUpdate, script.warnDays);
    });

    test('boundary: exactly 120 days → ERROR, not WARN', () {
      const contents =
          '**Last updated:** 2025-12-26'; // 120 days before 2026-04-25
      final result = script.evaluate(contents, now: fixedNow);

      expect(result.exitCode, 1);
      expect(result.message, startsWith('ERROR'));
      expect(result.daysSinceUpdate, script.failDays);
    });
  });
}
