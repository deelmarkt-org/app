#!/usr/bin/env dart

/// test_affected.dart — Run tests only for staged Dart files.
///
/// Cross-platform (macOS, Linux, Windows). Requires only Dart SDK.
///
/// Mapping rules:
///   lib/core/design_system/colors.dart  → test/core/design_system_test.dart
///                                         test/core/design_system/colors_test.dart
///   lib/features/home/data/repo.dart    → test/features/home/data/repo_test.dart
///   lib/widgets/buttons/deel_button.dart → test/widgets/buttons/deel_button_test.dart
///   test/anything_test.dart             → runs directly
///
/// Core files (main.dart, theme, router, l10n) trigger full suite.
/// If no matching test files found, exits 0 (nothing to test).
import 'dart:io';

/// Files that affect the entire app — change triggers full suite.
const coreFiles = [
  'lib/main.dart',
  'lib/core/design_system/theme.dart',
  'lib/core/router/app_router.dart',
  'lib/core/l10n/l10n.dart',
];

void main() async {
  // Get staged .dart files
  final result = await Process.run('git', [
    'diff',
    '--cached',
    '--name-only',
    '--diff-filter=ACMR',
    '--',
    '*.dart',
  ]);

  final staged =
      (result.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

  if (staged.isEmpty) {
    print('No staged Dart files — skipping tests.');
    exit(0);
  }

  // Check for core file changes → full suite
  for (final core in coreFiles) {
    if (staged.contains(core)) {
      print('Core file changed ($core) — running full test suite.');
      final testResult = await Process.run('flutter', [
        'test',
        '--no-pub',
      ], runInShell: true);
      stdout.write(testResult.stdout);
      stderr.write(testResult.stderr);
      exit(testResult.exitCode);
    }
  }

  // Map staged files to test files
  final testFiles = <String>{};

  for (final file in staged) {
    // Normalise path separators
    final normalised = file.replaceAll('\\', '/');

    if (normalised.startsWith('test/') && normalised.endsWith('_test.dart')) {
      // Already a test file — run directly
      testFiles.add(normalised);
    } else if (normalised.startsWith('lib/')) {
      // Map lib/X.dart → test/X_test.dart
      final testPath = normalised
          .replaceFirst('lib/', 'test/')
          .replaceFirst(RegExp(r'\.dart$'), '_test.dart');
      if (File(testPath).existsSync()) {
        testFiles.add(testPath);
      }

      // Also check directory-level test file
      // lib/core/design_system/colors.dart → test/core/design_system_test.dart
      final parts = testPath.split('/');
      if (parts.length >= 3) {
        final dirName = parts[parts.length - 2];
        final parentParts = parts.sublist(0, parts.length - 2);
        final dirTest = '${parentParts.join("/")}/${dirName}_test.dart';
        if (File(dirTest).existsSync()) {
          testFiles.add(dirTest);
        }
      }
    }
  }

  if (testFiles.isEmpty) {
    print('No matching test files for changed sources — skipping.');
    exit(0);
  }

  print('Running affected tests:');
  for (final f in testFiles) {
    print('  → $f');
  }

  final testResult = await Process.run('flutter', [
    'test',
    '--no-pub',
    ...testFiles,
  ], runInShell: true);
  stdout.write(testResult.stdout);
  stderr.write(testResult.stderr);
  exit(testResult.exitCode);
}
