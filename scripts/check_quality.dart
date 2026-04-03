#!/usr/bin/env dart
// ignore_for_file: avoid_print

// CLAUDE.md quality gate — catches the top recurring issues before commit.
//
// Pre-commit (default): file length, cross-feature imports, hardcoded strings,
//   missing Semantics, setState, FutureBuilder/StreamBuilder.
// Pre-push (--thorough): duplicate string literals, nested ternaries,
//   long methods.
//
// Rules are read from CLAUDE.md §12 (QUALITY_RULES_START block).
// Usage:
//   dart run scripts/check_quality.dart            # pre-commit (staged files)
//   dart run scripts/check_quality.dart --thorough  # pre-push (all changed files)
//   dart run scripts/check_quality.dart --all       # check all lib/ files
import 'dart:io';

void main(List<String> args) async {
  final thorough = args.contains('--thorough');
  final all = args.contains('--all');

  final files = all ? await _allLibFiles() : await _stagedFiles();
  if (files.isEmpty) {
    print('No Dart files to check.');
    exit(0);
  }

  final config = _loadConfig();
  final violations = <String>[];

  for (final file in files) {
    final content = File(file).readAsStringSync();
    final lines = content.split('\n');

    _checkFileLength(file, lines.length, config, violations);
    _checkCrossFeatureImports(file, lines, config, violations);

    if (_isPresentationFile(file)) {
      _checkHardcodedStrings(file, lines, violations);
      _checkMissingSemantics(file, content, violations);
      _checkSetState(file, content, config, violations);
      _checkRawAsyncWidgets(file, content, violations);
    }

    if (thorough) {
      _checkDuplicateStrings(file, lines, violations);
      _checkNestedTernaries(file, lines, violations);
      _checkLongMethods(file, lines, violations);
    }
  }

  if (violations.isEmpty) {
    print('Quality check passed (${files.length} files).');
    exit(0);
  }

  print('Quality check found ${violations.length} issue(s):\n');
  for (final v in violations) {
    print(v);
  }
  print('\nFix the issues above before committing.');
  exit(1);
}

// ── File discovery ─────────────────────────────────────────────────────

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
      .map((l) => l.trim())
      .where((l) => l.startsWith('lib/') && l.endsWith('.dart'))
      .where((l) => !l.endsWith('.g.dart') && !l.endsWith('.freezed.dart'))
      .toList();
}

Future<List<String>> _allLibFiles() async {
  final result = await Process.run('find', ['lib', '-name', '*.dart']);
  return (result.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.endsWith('.dart'))
      .where((l) => !l.endsWith('.g.dart') && !l.endsWith('.freezed.dart'))
      .toList();
}

// ── Config from CLAUDE.md ──────────────────────────────────────────────

class _Config {
  Map<String, int> fileLength = {
    'screen': 200,
    'viewmodel': 150,
    'repository': 200,
    'usecase': 50,
    'model': 100,
    'test': 300,
    'utility': 100,
    'default': 200,
  };
  Set<String> setStateAllowlist = {};
  Set<String> crossFeatureExempt = {
    'lib/core/router/app_router.dart',
    'lib/core/services/repository_providers.dart',
  };
}

_Config _loadConfig() {
  final config = _Config();
  final file = File('CLAUDE.md');
  if (!file.existsSync()) return config;

  final content = file.readAsStringSync();
  const startTag = '<!-- QUALITY_RULES_START';
  const endTag = 'QUALITY_RULES_END -->';
  final startIdx = content.indexOf(startTag);
  final endIdx = content.indexOf(endTag);
  if (startIdx == -1 || endIdx == -1) return config;

  final block = content.substring(startIdx + startTag.length, endIdx);
  String? currentSection;

  for (final line in block.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    if (trimmed.startsWith('file_length:')) {
      currentSection = 'file_length';
      continue;
    }
    if (trimmed.startsWith('setState_allowlist:')) {
      currentSection = 'setState';
      continue;
    }
    if (trimmed.startsWith('cross_feature_import_exempt:')) {
      currentSection = 'exempt';
      continue;
    }

    if (trimmed.startsWith('- ') && currentSection == 'setState') {
      config.setStateAllowlist.add(trimmed.substring(2).trim());
    }
    if (trimmed.startsWith('- ') && currentSection == 'exempt') {
      config.crossFeatureExempt.add(trimmed.substring(2).trim());
    }
    if (trimmed.contains(':') && currentSection == 'file_length') {
      final parts = trimmed.split(':');
      final key = parts[0].trim();
      final value = int.tryParse(parts[1].trim());
      if (value != null) config.fileLength[key] = value;
    }
  }

  return config;
}

// ── Checks ─────────────────────────────────────────────────────────────

bool _isPresentationFile(String path) {
  return path.contains('/presentation/') || path.startsWith('lib/widgets/');
}

String _fileType(String path) {
  if (path.contains('_screen.dart') || path.contains('_page.dart')) {
    return 'screen';
  }
  if (path.contains('/viewmodels/') ||
      path.contains('_notifier.dart') ||
      path.contains('_viewmodel.dart')) {
    return 'viewmodel';
  }
  if (path.contains('/data/') &&
      !path.contains('/entities/') &&
      !path.contains('/dto/')) {
    return 'repository';
  }
  if (path.contains('/usecases/') || path.contains('/use_cases/')) {
    return 'usecase';
  }
  if (path.contains('/entities/') || path.contains('/dto/')) {
    return 'model';
  }
  if (path.startsWith('test/')) return 'test';
  if (path.contains('/utils/')) return 'utility';
  return 'default';
}

void _checkFileLength(
  String file,
  int lineCount,
  _Config config,
  List<String> violations,
) {
  if (file.contains('/dev/')) return;
  // Multi-class files (extracted widgets) get +50 per extra class
  final content = File(file).readAsStringSync();
  final classCount =
      RegExp(r'^class\s', multiLine: true).allMatches(content).length;
  final type = _fileType(file);
  final baseLimit = config.fileLength[type] ?? config.fileLength['default']!;
  final limit = baseLimit + ((classCount > 1 ? classCount - 1 : 0) * 50);
  if (lineCount > limit) {
    violations.add(
      '  FILE_LENGTH  $file: $lineCount lines (limit $limit for $type${classCount > 1 ? ', +${(classCount - 1) * 50} for $classCount classes' : ''}) [CLAUDE.md §2.1]',
    );
  }
}

void _checkCrossFeatureImports(
  String file,
  List<String> lines,
  _Config config,
  List<String> violations,
) {
  if (!file.startsWith('lib/features/')) return;
  if (config.crossFeatureExempt.contains(file)) return;

  final featureMatch = RegExp(r'lib/features/([^/]+)/').firstMatch(file);
  if (featureMatch == null) return;
  final ownFeature = featureMatch.group(1)!;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('import ')) continue;
    final importMatch = RegExp(r'features/([^/]+)/').firstMatch(line);
    if (importMatch != null && importMatch.group(1) != ownFeature) {
      violations.add(
        '  CROSS_IMPORT  $file:${i + 1}: imports from features/${importMatch.group(1)} [CLAUDE.md §1.2]',
      );
    }
  }
}

void _checkHardcodedStrings(
  String file,
  List<String> lines,
  List<String> violations,
) {
  if (file.contains('/dev/')) return;
  final textPattern = RegExp(r'''Text\(\s*['"]([^'"\$]+)['"]\s*\)''');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('.tr()')) continue;
    if (line.trimLeft().startsWith('//')) continue;
    final match = textPattern.firstMatch(line);
    if (match != null) {
      final text = match.group(1)!;
      // Skip single characters, numbers, and common non-translatable strings
      if (text.length <= 2 || RegExp(r'^\d+$').hasMatch(text)) continue;
      violations.add(
        '  HARDCODED_STRING  $file:${i + 1}: Text(\'$text\') — use l10n key with .tr() [CLAUDE.md §3.3]',
      );
    }
  }
}

void _checkMissingSemantics(
  String file,
  String content,
  List<String> violations,
) {
  if (file.contains('/dev/')) return;
  final interactiveWidgets = ['InkWell', 'GestureDetector', 'IconButton'];
  final hasInteractive = interactiveWidgets.any((w) => content.contains(w));
  if (hasInteractive && !content.contains('Semantics(')) {
    violations.add(
      '  MISSING_SEMANTICS  $file: has interactive widgets but no Semantics() [CLAUDE.md §10]',
    );
  }
}

void _checkSetState(
  String file,
  String content,
  _Config config,
  List<String> violations,
) {
  if (!content.contains('setState(')) return;
  if (config.setStateAllowlist.any((pattern) {
    if (pattern.contains('**')) {
      final regex = pattern.replaceAll('**', '.*').replaceAll('*', '[^/]*');
      return RegExp(regex).hasMatch(file);
    }
    return file == pattern;
  })) {
    return;
  }

  violations.add(
    '  SET_STATE  $file: uses setState() — use Riverpod instead [CLAUDE.md §1.3]',
  );
}

void _checkRawAsyncWidgets(
  String file,
  String content,
  List<String> violations,
) {
  for (final widget in ['FutureBuilder', 'StreamBuilder']) {
    if (content.contains('$widget<') || content.contains('$widget(')) {
      violations.add(
        '  RAW_ASYNC  $file: uses $widget — use Riverpod provider instead [CLAUDE.md §1.3]',
      );
    }
  }
}

// ── Thorough checks (pre-push) ─────────────────────────────────────────

void _checkDuplicateStrings(
  String file,
  List<String> lines,
  List<String> violations,
) {
  final stringPattern = RegExp(r"""'([^']{4,})'|'([^']{4,})'""");
  final counts = <String, int>{};

  for (final line in lines) {
    if (line.trimLeft().startsWith('//')) continue;
    for (final match in stringPattern.allMatches(line)) {
      final str = match.group(1) ?? match.group(2);
      if (str != null) counts[str] = (counts[str] ?? 0) + 1;
    }
  }

  for (final entry in counts.entries) {
    if (entry.value >= 3) {
      violations.add(
        '  DUPLICATE_STRING  $file: \'${entry.key}\' appears ${entry.value} times — extract to constant [SonarCloud S1192]',
      );
    }
  }
}

void _checkNestedTernaries(
  String file,
  List<String> lines,
  List<String> violations,
) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // Count ? operators on the line (excluding ?.  and ??)
    final ternaryCount =
        RegExp(r'(?<!\?)\?(?!\?|\.|\s*$)').allMatches(line).length;
    if (ternaryCount >= 2) {
      violations.add(
        '  NESTED_TERNARY  $file:${i + 1}: nested ternary — extract to variable [SonarCloud S3358]',
      );
    }
  }
}

void _checkLongMethods(
  String file,
  List<String> lines,
  List<String> violations,
) {
  var methodStart = -1;
  var braceDepth = 0;
  String? methodName;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // Detect method/function declarations
    if (braceDepth == 1 || braceDepth == 0) {
      final methodMatch = RegExp(r'^\s+\w.*\b(\w+)\s*\(').firstMatch(line);
      if (methodMatch != null && line.contains('{')) {
        methodStart = i;
        methodName = methodMatch.group(1);
      }
    }

    braceDepth += '{'.allMatches(line).length;
    braceDepth -= '}'.allMatches(line).length;

    if (methodStart >= 0 && braceDepth <= 1 && line.contains('}')) {
      final length = i - methodStart + 1;
      if (length > 60 && methodName != null) {
        violations.add(
          '  LONG_METHOD  $file:${methodStart + 1}: $methodName() is $length lines (>60) — risk of high cognitive complexity [SonarCloud S3776]',
        );
      }
      methodStart = -1;
      methodName = null;
    }
  }
}
