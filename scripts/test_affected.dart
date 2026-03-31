#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Run tests only for staged Dart files. Cross-platform (macOS, Linux, Windows).
//
// Mapping rules:
//   lib/core/design_system/colors.dart  → test/core/design_system_test.dart
//                                         test/core/design_system/colors_test.dart
//   lib/features/home/data/repo.dart    → test/features/home/data/repo_test.dart
//   test/anything_test.dart             → runs directly
//
// Core files + config files trigger full suite.
import 'dart:io';

/// Files that affect the entire app — change triggers full suite.
const coreFiles = [
  'lib/main.dart',
  'lib/core/design_system/theme.dart',
  'lib/core/router/app_router.dart',
  'lib/core/l10n/l10n.dart',
  'pubspec.yaml',
  'pubspec.lock',
];

Future<void> main() async {
  // Verify git is available
  try {
    final gitCheck = await Process.run('git', ['--version']);
    if (gitCheck.exitCode != 0) {
      print('Error: git is not available on PATH.');
      exit(1);
    }
  } on ProcessException catch (e) {
    print('Error: git is not available on PATH: $e');
    exit(1);
  }

  // Get staged .dart files
  final result = await Process.run('git', [
    'diff',
    '--cached',
    '--name-only',
    '--diff-filter=ACMR',
    '--',
    '*.dart',
    'pubspec.yaml',
    'pubspec.lock',
  ]);

  if (result.exitCode != 0) {
    print('Error: git diff failed: ${result.stderr}');
    exit(1);
  }

  final staged =
      (result.stdout.toString())
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

  if (staged.isEmpty) {
    print('No staged Dart files — skipping tests.');
    exit(0);
  }

  // Check for core/config file changes → full suite
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
    final normalised = file.replaceAll('\\', '/');

    if (normalised.startsWith('test/') && normalised.endsWith('_test.dart')) {
      testFiles.add(normalised);
    } else if (normalised.startsWith('lib/')) {
      // lib/X.dart → test/X_test.dart
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
