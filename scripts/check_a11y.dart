#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Static accessibility audit — closes P-54 D16/C2 ("EAA enforcement is
// live; Semantics-label-only is insufficient"). Runs over Dart source
// and flags the regression classes that golden tests can't catch:
//
//   1. Hardcoded touch-target heights/widths < 44 px on tappable widgets
//      (CLAUDE.md §10 — "All interactive elements: ≥ 44×44px touch
//      targets"). Specifically: GestureDetector / InkWell / IconButton
//      / TextButton with explicit width/height props below 44.
//   2. Color literals (`Color(0xFF...)`) outside the design-token
//      directories — proxy for "user passed a non-token color into a
//      Text style that risks <4.5:1 contrast on dark mode".
//
// Static `Semantics`-on-tap detection is intentionally OUT of scope for
// this iteration — robust detection requires multi-line widget-tree
// reasoning (does a parent widget already provide `Semantics(button:
// true, label: ...)`?) which is closer to AST analysis than line-based
// linting. Tracked as a follow-up; runtime semantics coverage is
// already enforced by widget tests and the screenshot drivers.
//
// This is a STATIC audit — it can't measure actual contrast at runtime.
// For runtime contrast verification, see the screenshot drivers under
// `test/screenshots/` which capture full-frame pixels.
//
// Usage:
//   dart run scripts/check_a11y.dart                # check staged files
//   dart run scripts/check_a11y.dart --all          # check all lib/
//   dart run scripts/check_a11y.dart <path> [path]  # check explicit paths
//
// Reference: docs/PLAN-P54-screen-decomposition.md §9 + ADR-027.
import 'dart:io';

void main(List<String> args) async {
  final all = args.contains('--all');
  final positional = args
      .where((a) => !a.startsWith('--') && a.endsWith('.dart'))
      .toList(growable: false);

  final List<String> files;
  if (positional.isNotEmpty) {
    files = positional.map((p) => p.replaceAll(r'\', '/')).toList();
  } else if (all) {
    files = await _allLibFiles();
  } else {
    files = await _stagedFiles();
  }

  if (files.isEmpty) {
    print('No Dart files to check.');
    exit(0);
  }

  final violations = <String>[];
  for (final file in files) {
    final content = File(file).readAsStringSync();
    final lines = content.split('\n');

    if (_isPresentationFile(file)) {
      _checkSmallTouchTargets(file, lines, violations);
      _checkRawColorLiterals(file, lines, violations);
    }
  }

  if (violations.isEmpty) {
    print('A11y check passed (${files.length} files).');
    exit(0);
  }

  print('A11y check found ${violations.length} issue(s):\n');
  for (final v in violations) {
    print(v);
  }
  print(
    '\nFix references:\n'
    '  - Touch targets: CLAUDE.md §10 — ≥44×44 px on tappable widgets\n'
    '  - Color tokens: lib/core/design_system/colors.dart (DeelmarktColors)\n'
    '  - Semantics: docs/design-system/accessibility.md',
  );
  exit(1);
}

Future<List<String>> _stagedFiles() async {
  final result = await Process.run('git', [
    'diff',
    '--cached',
    '--name-only',
    '--diff-filter=ACMR',
    '--',
    '*.dart',
  ]);
  return (result.stdout as String)
      .split('\n')
      .map((l) => l.trim().replaceAll(r'\', '/'))
      .where((l) => l.startsWith('lib/') && l.endsWith('.dart'))
      .where((l) => !l.endsWith('.g.dart') && !l.endsWith('.freezed.dart'))
      .toList();
}

Future<List<String>> _allLibFiles() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return [];
  return libDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart'))
      .where((p) => !p.endsWith('.g.dart') && !p.endsWith('.freezed.dart'))
      .toList();
}

bool _isPresentationFile(String path) {
  return path.contains('/presentation/') || path.startsWith('lib/widgets/');
}

/// Flags explicit `width: <44` or `height: <44` on tappable surfaces.
///
/// We restrict the check to lines that mention a tappable widget within
/// a small surrounding window so we don't false-positive on container
/// graphics that happen to be small (e.g. status dots, tiny icons inside
/// larger tap areas).
void _checkSmallTouchTargets(
  String file,
  List<String> lines,
  List<String> violations,
) {
  const tappableWidgets = [
    'GestureDetector(',
    'InkWell(',
    'IconButton(',
    'TextButton(',
    'OutlinedButton(',
    'ElevatedButton(',
  ];
  final dimRegex = RegExp(r'\b(width|height):\s*([0-9]+(?:\.[0-9]+)?)\b');

  for (var i = 0; i < lines.length; i++) {
    // Use `allMatches` so a single line containing BOTH `width:` and
    // `height:` (e.g. `SizedBox(width: 100, height: 20)`) is fully
    // audited. The previous `firstMatch` would short-circuit on the
    // first dimension, missing a sub-44 second dimension entirely
    // (Gemini PR #241 review HIGH).
    final matches = dimRegex.allMatches(lines[i]).toList();
    if (matches.isEmpty) continue;

    // Tappable check is per-LINE (not per-match) because the lookback
    // window is identical for every match on the line. Compute once.
    final lookbackStart = i - 8 >= 0 ? i - 8 : 0;
    final window = lines.sublist(lookbackStart, i + 1).join('\n');
    final isTappable = tappableWidgets.any(window.contains);
    if (!isTappable) continue;

    for (final dimMatch in matches) {
      final dim = double.parse(dimMatch.group(2)!);
      if (dim >= 44) continue;
      violations.add(
        '  TOUCH_TARGET   $file:${i + 1}: '
        '${dimMatch.group(1)}: $dim — must be ≥44 on tappable surfaces '
        '(CLAUDE.md §10)',
      );
    }
  }
}

/// Flags `Color(0xFF...)` literals outside the design-system directory.
/// The exception list mirrors the CLAUDE.md §3.3 token enforcement.
void _checkRawColorLiterals(
  String file,
  List<String> lines,
  List<String> violations,
) {
  // Token files own raw colors by definition.
  if (file.startsWith('lib/core/design_system/')) return;
  if (file.startsWith('lib/core/theme/')) return;

  final colorRegex = RegExp(r'\bColor\(0x[0-9A-Fa-f]{8}\)');

  for (var i = 0; i < lines.length; i++) {
    if (colorRegex.hasMatch(lines[i])) {
      violations.add(
        '  RAW_COLOR      $file:${i + 1}: '
        'use DeelmarktColors token instead of literal Color(0xFF…) '
        '(CLAUDE.md §3.3 + §10 contrast)',
      );
    }
  }
}
