import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the NESTED_TERNARY regex used in `scripts/check_quality.dart`.
///
/// The fix (PR #111) changed the `?` match from a simple count to
/// `r' \?(?!\?|\.)` (space-prefixed, not `??` null-coalesce, not `?.`
/// null-safe call). This avoids false positives on nullable type
/// annotations such as `T? Function()?` and `String? Function(String?)?`.
void main() {
  // Mirror the exact regex from scripts/check_quality.dart
  const ternaryRegex = r' \?(?!\?|\.)';

  int countTernaries(String line) =>
      RegExp(ternaryRegex).allMatches(line).length;

  group('NESTED_TERNARY regex — no false positives', () {
    test('nullable type annotation T? Function()? does not match', () {
      // The `?` tokens here have no leading space — they are type annotations.
      const line = '  SellImage copyWith({T? Function()? storagePath,})';
      expect(countTernaries(line), lessThan(2));
    });

    test('nullable parameter type String? does not match', () {
      const line = '  String? Function(String?)? callback,';
      expect(countTernaries(line), lessThan(2));
    });

    test('null-coalesce ?? does not match', () {
      const line = '  final x = a ?? b ?? c;';
      expect(countTernaries(line), lessThan(2));
    });

    test('null-safe call ?. does not match', () {
      const line = '  final y = obj?.field?.value;';
      expect(countTernaries(line), lessThan(2));
    });
  });

  group('NESTED_TERNARY regex — true positives', () {
    test('two ternary operators on the same line are caught', () {
      const line = '  final z = a ? b ? c : d : e;';
      expect(countTernaries(line), greaterThanOrEqualTo(2));
    });

    test('inline ternary in argument list is caught', () {
      const line = '  foo(a ? 1 : 2, b ? 3 : 4);';
      expect(countTernaries(line), greaterThanOrEqualTo(2));
    });
  });
}
