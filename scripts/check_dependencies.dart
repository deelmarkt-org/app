#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Dependency-pin guard — fails on permissive `: any` constraints in
// `pubspec.yaml`. Closes the P-58a follow-up promised in PLAN-P58:
// `intl: any` was the original §M2 audit finding; this script prevents
// the regression class entirely.
//
// `: any` allows the constraint solver to pick any future major version
// — a silent supply-chain risk and a reproducibility hole. ACM/Omnibus
// (price-glyph rendering) and BTW formatting both depend on stable intl
// behaviour.
//
// Allowed exceptions (extremely rare, must be justified inline with a
// `# DEPENDENCY_PIN_EXEMPT:` marker on the same line):
//   - dependency_overrides — explicit local overrides for SDK-shipped
//     packages where pinning would conflict with the Flutter SDK.
//
// Usage:
//   dart run scripts/check_dependencies.dart            # check pubspec.yaml
//   dart run scripts/check_dependencies.dart --strict   # also fails on `^0.0.x`
//
// Reference: docs/PLAN-P58-pin-intl.md §10 (P-58a follow-up).
import 'dart:io';

void main(List<String> args) async {
  final strict = args.contains('--strict');
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('ERROR: pubspec.yaml not found in working directory.');
    exit(1);
  }

  final content = pubspec.readAsStringSync();
  final violations = scan(content, strict: strict);

  if (violations.isEmpty) {
    print('Dependency pin check passed.');
    exit(0);
  }

  print(
    'Dependency pin check found ${violations.length} permissive '
    'constraint(s) in pubspec.yaml:\n',
  );
  for (final v in violations) {
    print(v);
  }
  print(
    '\nFix: replace `: any` with a caret range like `^X.Y.Z` so security '
    'patches still flow but a major bump is an explicit review event.',
  );
  exit(1);
}

/// Scans `pubspec.yaml` content for permissive constraints, returning a
/// list of human-readable violation strings.
///
/// Exposed for unit testing — the [main] function only handles file I/O
/// and exit codes.
List<String> scan(String content, {required bool strict}) {
  final violations = <String>[];
  final lines = content.split('\n');

  // Track which top-level YAML section we're inside. We only enforce
  // pins under `dependencies:` and `dev_dependencies:` (NOT
  // `dependency_overrides:` which is the documented escape hatch).
  String? section;

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final line = raw.trimRight();

    // Top-level section header (no indentation, ends with `:`).
    if (RegExp(r'^[a-zA-Z_]+:\s*(#.*)?$').hasMatch(line)) {
      section = line.split(':').first.trim();
      continue;
    }

    if (section != 'dependencies' && section != 'dev_dependencies') continue;

    // Match a dependency entry: `  package_name: <constraint>`.
    final match = RegExp(
      r'^\s{2,4}([a-z0-9_]+):\s*(.+?)(\s+#.*)?$',
    ).firstMatch(line);
    if (match == null) continue;

    final pkg = match.group(1)!;
    // Strip surrounding quotes if present — YAML supports both
    // `intl: ">=0.20.0"` and `intl: >=0.20.0`. Without stripping, the
    // constraint regex below misses the quoted form.
    final constraint = _stripQuotes(match.group(2)!.trim());
    final hasExemption = (match.group(3) ?? '').contains(
      'DEPENDENCY_PIN_EXEMPT',
    );

    if (hasExemption) continue;

    // Block `any` and bare unbounded constraints (`>=X.Y.Z` with no upper).
    if (constraint == 'any') {
      violations.add(
        '  pubspec.yaml:${i + 1}  $pkg: any  '
        '— defeats reproducible builds; use `^X.Y.Z`',
      );
      continue;
    }
    if (RegExp(r'^>=\s*[0-9.]+(\s*<\s*[0-9.]+)?$').hasMatch(constraint)) {
      // `>=X.Y.Z` without `<` upper bound is permissive.
      if (!constraint.contains('<')) {
        violations.add(
          '  pubspec.yaml:${i + 1}  $pkg: $constraint  '
          '— missing upper bound; use `^X.Y.Z`',
        );
      }
      continue;
    }

    // Strict mode: also flag pre-1.0 caret constraints since those bump
    // on minor (`^0.20.2` allows up to `<0.21.0`). Documented hazard.
    if (strict && RegExp(r'^\^0\.[0-9]+\.[0-9]+').hasMatch(constraint)) {
      violations.add(
        '  pubspec.yaml:${i + 1}  $pkg: $constraint  '
        '— strict-mode warning: pre-1.0 caret allows minor bumps; '
        'consider tilde `~$constraint` if API stability is critical',
      );
    }
  }

  return violations;
}

/// Removes a single layer of matching `"..."` or `'...'` wrapping if
/// present, otherwise returns [s] unchanged.
String _stripQuotes(String s) {
  if (s.length < 2) return s;
  final first = s[0];
  final last = s[s.length - 1];
  if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
    return s.substring(1, s.length - 1);
  }
  return s;
}
