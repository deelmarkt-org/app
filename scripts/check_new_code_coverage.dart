#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Checks test coverage on new/changed Dart source files in the current branch.
//
// Compares the current branch against `dev` (or the branch passed as arg)
// and reports coverage only for changed `lib/` files.
//
// Exit code 0 = pass, 1 = below threshold.
//
// Usage:
//   dart run scripts/check_new_code_coverage.dart          # default 80%
//   dart run scripts/check_new_code_coverage.dart --min=70  # custom threshold
import 'dart:io';

const _defaultThreshold = 80;
const _baseBranch = 'origin/dev';

void main(List<String> args) async {
  final threshold = _parseThreshold(args);

  // 1. Run flutter test with coverage
  print('Running flutter test --coverage ...');
  final testResult = await Process.run('flutter', [
    'test',
    '--no-pub',
    '--coverage',
  ], runInShell: true);
  if (testResult.exitCode != 0) {
    print('Tests failed — cannot check coverage.');
    print(testResult.stderr);
    exit(1);
  }

  // 2. Get changed lib/ files vs base branch
  final diffResult = await Process.run('git', [
    'diff',
    '--name-only',
    '--diff-filter=ACMR',
    _baseBranch,
    '--',
    'lib/',
  ]);
  final changedFiles =
      (diffResult.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where(
            (l) =>
                l.endsWith('.dart') &&
                !l.endsWith('.g.dart') &&
                !l.contains(
                  '/supabase/',
                ) && // Supabase repos need integration tests
                !_isBarrelReexport(l),
          )
          .toList();

  if (changedFiles.isEmpty) {
    print('No changed lib/ files found — skipping coverage check.');
    exit(0);
  }

  // 3. Parse lcov.info
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('coverage/lcov.info not found — run flutter test --coverage first.');
    exit(1);
  }

  final coverage = _parseLcov(lcovFile.readAsStringSync());

  // 4. Calculate coverage for changed files only
  var totalHit = 0;
  var totalFound = 0;
  final uncovered = <String, double>{};

  for (final file in changedFiles) {
    final data = coverage[file];
    if (data == null) {
      // File has no coverage data at all (0%)
      uncovered[file] = 0;
      continue;
    }
    totalHit += data.hit;
    totalFound += data.found;
    final pct =
        data.found > 0 ? (data.hit / data.found * 100).toDouble() : 100.0;
    if (pct < threshold) {
      uncovered[file] = pct;
    }
  }

  final overallPct = totalFound > 0 ? (totalHit / totalFound * 100) : 100;

  // 5. Report
  print('');
  print(
    'New code coverage: ${overallPct.toStringAsFixed(1)}% '
    '($totalHit/$totalFound lines)',
  );
  print('Threshold: $threshold%');
  print('Changed files: ${changedFiles.length}');

  if (uncovered.isNotEmpty) {
    print('');
    print('Files below threshold:');
    for (final entry in uncovered.entries) {
      print('  ${entry.value.toStringAsFixed(1)}%  ${entry.key}');
    }
  }

  if (overallPct < threshold) {
    print('');
    print(
      'FAIL: New code coverage ${overallPct.toStringAsFixed(1)}% '
      'is below $threshold% threshold.',
    );
    exit(1);
  }

  print('');
  print('PASS: New code coverage meets $threshold% threshold.');
}

// Barrel re-export files have no executable code — exclude from coverage.
bool _isBarrelReexport(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return false;
  final content = file.readAsStringSync().trim();
  final lines =
      content
          .split('\n')
          .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('//'))
          .toList();
  return lines.length == 1 && lines.first.startsWith('export ');
}

int _parseThreshold(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--min=')) {
      return int.tryParse(arg.substring(6)) ?? _defaultThreshold;
    }
  }
  return _defaultThreshold;
}

class _FileCoverage {
  int hit = 0;
  int found = 0;
}

Map<String, _FileCoverage> _parseLcov(String content) {
  final result = <String, _FileCoverage>{};
  String? currentFile;

  for (final line in content.split('\n')) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('LH:') && currentFile != null) {
      result.putIfAbsent(currentFile, _FileCoverage.new).hit =
          int.tryParse(line.substring(3)) ?? 0;
    } else if (line.startsWith('LF:') && currentFile != null) {
      result.putIfAbsent(currentFile, _FileCoverage.new).found =
          int.tryParse(line.substring(3)) ?? 0;
    } else if (line == 'end_of_record') {
      currentFile = null;
    }
  }

  return result;
}
