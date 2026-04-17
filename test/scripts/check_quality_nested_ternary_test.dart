import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the NESTED_TERNARY regex and ADR-025 sentinel allowlist
/// used in `scripts/check_quality.dart`.
///
/// The fix (PR #111) changed the `?` match from a simple count to
/// `r' \?(?!\?|\.)` (space-prefixed, not `??` null-coalesce, not `?.`
/// null-safe call). This avoids false positives on nullable type
/// annotations such as `T? Function()?` and `String? Function(String?)?`.
///
/// ADR-025 adds a sentinel allowlist for `*_copy_with.dart` files where the
/// pattern `identifier != null ? identifier() : this.identifier` is used to
/// distinguish "keep current value" from "clear to null" in copyWith.
void main() {
  // Mirror the exact regex from scripts/check_quality.dart
  const ternaryRegex = r' \?(?!\?|\.)';

  // Mirror ADR-025 sentinel pattern from scripts/check_quality.dart
  final sentinelPattern = RegExp(
    r'\w+\s*!=\s*null\s*\?\s*\w+\(\)\s*:\s*this\.\w+',
  );

  int countTernaries(String line) =>
      RegExp(ternaryRegex).allMatches(line).length;

  bool isSentinelLine(String line) => sentinelPattern.hasMatch(line);

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

  // ADR-025: sentinel copyWith allowlist tests
  group('ADR-025 sentinel allowlist — matches known copy_with lines', () {
    test('categoryL1Id sentinel line matches', () {
      const line =
          '      categoryL1Id: categoryL1Id != null ? categoryL1Id() : this.categoryL1Id,';
      expect(isSentinelLine(line), isTrue);
    });

    test('condition sentinel line matches', () {
      const line =
          '      condition: condition != null ? condition() : this.condition,';
      expect(isSentinelLine(line), isTrue);
    });

    test('errorKey sentinel line matches', () {
      const line =
          '      errorKey: errorKey != null ? errorKey() : this.errorKey,';
      expect(isSentinelLine(line), isTrue);
    });

    test('createdListingId sentinel line matches', () {
      const line =
          '          createdListingId != null ? createdListingId() : this.createdListingId,';
      expect(isSentinelLine(line), isTrue);
    });
  });

  group('ADR-025 sentinel allowlist — does NOT over-match', () {
    test('real nested ternary is not a sentinel', () {
      const line = '  final z = a ? b ? c : d : e;';
      expect(isSentinelLine(line), isFalse);
    });

    test('inline ternary in argument list is not a sentinel', () {
      const line = '  foo(a ? 1 : 2, b ? 3 : 4);';
      expect(isSentinelLine(line), isFalse);
    });

    test('simple single ternary is not a sentinel', () {
      const line = '  final x = isActive ? Colors.green : Colors.grey;';
      expect(isSentinelLine(line), isFalse);
    });

    test('null-coalesce is not a sentinel', () {
      const line = '  final x = a ?? b ?? c;';
      expect(isSentinelLine(line), isFalse);
    });
  });
}
