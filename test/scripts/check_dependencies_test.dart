import 'package:flutter_test/flutter_test.dart';

import '../../scripts/check_dependencies.dart' as script;

/// Tests for `scripts/check_dependencies.dart` — closes the P-58a
/// follow-up promised in PLAN-P58.
///
/// The scanner is exposed as a pure function (`script.scan`) so tests
/// don't shell out to `dart run` (much faster + deterministic).
void main() {
  group('check_dependencies.scan — permissive `: any` detection', () {
    test('flags `package: any` in dependencies section', () {
      const yaml = '''
name: test_app
dependencies:
  flutter:
    sdk: flutter
  intl: any
  go_router: ^14.8.1
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, hasLength(1));
      expect(violations.first, contains('intl'));
      expect(violations.first, contains('any'));
    });

    test('flags `package: any` in dev_dependencies section', () {
      const yaml = '''
name: test_app
dev_dependencies:
  test: any
  mocktail: ^1.0.4
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, hasLength(1));
      expect(violations.first, contains('test'));
    });

    test('does NOT flag `: any` under dependency_overrides (escape hatch)', () {
      const yaml = '''
name: test_app
dependencies:
  go_router: ^14.8.1
dependency_overrides:
  package_info_plus: any
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, isEmpty);
    });

    test('respects inline `# DEPENDENCY_PIN_EXEMPT:` exemption marker', () {
      const yaml = '''
name: test_app
dependencies:
  intl: any  # DEPENDENCY_PIN_EXEMPT: SDK-coupled, see ADR-X
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, isEmpty);
    });

    test('flags `>=X.Y.Z` with no upper bound', () {
      const yaml = '''
name: test_app
dependencies:
  intl: ">=0.20.0"
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, hasLength(1));
      expect(violations.first, contains('upper bound'));
    });

    test('accepts `>=X.Y.Z <X.Y.Z` (bounded range)', () {
      const yaml = '''
name: test_app
dependencies:
  intl: ">=0.20.0 <0.21.0"
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, isEmpty);
    });

    test('accepts caret constraints like `^X.Y.Z`', () {
      const yaml = '''
name: test_app
dependencies:
  intl: ^0.20.2
  go_router: ^14.8.1
  flutter_riverpod: ^2.6.1
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, isEmpty);
    });

    test('--strict flags pre-1.0 caret as a warning', () {
      const yaml = '''
name: test_app
dependencies:
  intl: ^0.20.2
''';
      final lax = script.scan(yaml, strict: false);
      expect(lax, isEmpty);

      final strict = script.scan(yaml, strict: true);
      expect(strict, hasLength(1));
      expect(strict.first, contains('pre-1.0 caret'));
    });

    test('clusters multiple violations on a single scan', () {
      const yaml = '''
name: test_app
dependencies:
  pkg_a: any
  pkg_b: ">=1.0.0"
  pkg_c: ^2.0.0
''';
      final violations = script.scan(yaml, strict: false);
      expect(violations, hasLength(2));
    });
  });
}
