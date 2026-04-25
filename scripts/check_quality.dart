#!/usr/bin/env dart
// ignore_for_file: avoid_print

// CLAUDE.md quality gate — catches the top recurring issues before commit.
//
// Pre-commit (default): file length, cross-feature imports, hardcoded strings,
//   missing Semantics, setState, FutureBuilder/StreamBuilder.
// Pre-push (--thorough): duplicate string literals, nested ternaries,
//   long methods.
// Golden integrity (--check-goldens): detects byte-identical light/dark golden
//   pairs that indicate solid-color captures (see issue #203). Diagnostic only —
//   exits non-zero on violations so devs can inventory affected pairs locally.
//
// Rules are read from CLAUDE.md §12 (QUALITY_RULES_START block).
// Usage:
//   dart run scripts/check_quality.dart                # pre-commit (staged files)
//   dart run scripts/check_quality.dart --thorough     # pre-push (all changed)
//   dart run scripts/check_quality.dart --all          # check all lib/ files
//   dart run scripts/check_quality.dart --check-goldens # golden pair integrity
import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) async {
  // Golden integrity mode — standalone, exits immediately after check.
  if (args.contains('--check-goldens')) {
    final code = await _checkGoldenIdenticalPairs(
      'test/screenshots/drivers/goldens',
    );
    exit(code);
  }

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
      _checkScreenSpecReference(file, content, violations);
    }

    if (thorough) {
      _checkDuplicateStrings(file, lines, violations);
      _checkNestedTernaries(file, lines, violations);
      _checkLongMethods(file, lines, violations);
    }
  }

  // Missing test file + spec reference checks — separate from the main loop
  // because they only need the file path (not content). Skipped in --all mode
  // to avoid noise from pre-existing files without tests (169+ violations).
  if (!all) {
    for (final file in files) {
      _checkMissingTestFile(file, violations);
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
  Set<String> fileLengthExempt = {};
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
    if (trimmed.startsWith('file_length_exempt:')) {
      currentSection = 'fl_exempt';
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

    if (trimmed.startsWith('- ') && currentSection == 'fl_exempt') {
      config.fileLengthExempt.add(trimmed.substring(2).trim());
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

bool _matchesAnyPattern(String path, Set<String> patterns) {
  for (final pattern in patterns) {
    if (pattern.contains('**')) {
      final regex = pattern
          .replaceAll('.', r'\.')
          .replaceAll('**/', '(.*/)?')
          .replaceAll('**', '.*')
          .replaceAll('*', '[^/]*');
      if (RegExp('(.*/)?$regex').hasMatch(path)) return true;
    } else if (path == pattern) {
      return true;
    }
  }
  return false;
}

void _checkFileLength(
  String file,
  int lineCount,
  _Config config,
  List<String> violations,
) {
  if (file.contains('/dev/')) return;
  if (_matchesAnyPattern(file, config.fileLengthExempt)) return;
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
  final hasSemantics =
      content.contains('Semantics(') ||
      content.contains('tooltip:') ||
      content.contains('semanticLabel:');
  if (hasInteractive && !hasSemantics) {
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
  if (_matchesAnyPattern(file, config.setStateAllowlist)) return;

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

// ── Screen spec reference check ───────────────────────────────────────

/// Screen and widget files in presentation/ should have a
/// `/// Reference: docs/screens/...` doc comment linking to the spec.
/// Only applies to screen files (*_screen.dart) and top-level widget files
/// that correspond to a screen spec section.
void _checkScreenSpecReference(
  String file,
  String content,
  List<String> violations,
) {
  // Only check screen files — widgets may reference the parent screen spec
  // or may be purely generic (no spec). Screens always have a spec.
  if (!file.endsWith('_screen.dart')) return;

  final hasRef =
      content.contains('docs/screens/') || content.contains('docs/epics/');

  if (!hasRef) {
    violations.add(
      '  MISSING_SPEC_REF  $file: screen file has no /// Reference: docs/screens/... comment — check SCREEN-MAP.md [CLAUDE.md §4.2]',
    );
  }
}

// ── Missing test file check ───────────────────────────────────────────

/// Paths exempt from the "must have a test" rule.
const _testExemptPaths = [
  'lib/core/router/', // router config — tested via integration
  'lib/core/services/', // service wiring — tested via integration
  'lib/core/l10n/', // localisation config
  'lib/core/design_system/', // tokens/theme — tested via widget tests
  'lib/core/constants.dart', // just constants
  'lib/main.dart', // app entry point
];

/// Filename patterns exempt — these file types don't need individual tests.
const _testExemptPatterns = [
  '/mock/', // mock implementations — test infrastructure
  '/domain/repositories/', // repository interfaces — tested via implementations
  '/domain/exceptions', // exception classes — trivial data holders
  '_providers.dart', // Riverpod provider wiring — tested via consumers
  '_state.dart', // state classes — tested via notifier tests
];

void _checkMissingTestFile(String file, List<String> violations) {
  if (!file.startsWith('lib/')) return;
  if (file.endsWith('.g.dart') || file.endsWith('.freezed.dart')) return;

  // Skip exempt paths
  for (final exempt in _testExemptPaths) {
    if (file.startsWith(exempt)) return;
  }

  // Skip exempt patterns
  for (final pattern in _testExemptPatterns) {
    if (file.contains(pattern)) return;
  }

  // Map lib/X.dart → test/X_test.dart
  final testPath = file
      .replaceFirst('lib/', 'test/')
      .replaceFirst(RegExp(r'\.dart$'), '_test.dart');

  if (File(testPath).existsSync()) return;

  // Also accept a directory-level test:
  // lib/core/design_system/colors.dart → test/core/design_system_test.dart
  final parts = testPath.split('/');
  if (parts.length >= 3) {
    final dirName = parts[parts.length - 2];
    final parentParts = parts.sublist(0, parts.length - 2);
    final dirTest = '${parentParts.join("/")}/${dirName}_test.dart';
    if (File(dirTest).existsSync()) return;
  }

  violations.add(
    '  MISSING_TEST  $file: no corresponding test file found (expected $testPath) [CLAUDE.md §6]',
  );
}

// ── Thorough checks (pre-push) ─────────────────────────────────────────

void _checkDuplicateStrings(
  String file,
  List<String> lines,
  List<String> violations,
) {
  final stringPattern = RegExp(
    r"'([^']{4,})'|"
    r'"([^"]{4,})"',
  );
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

// ADR-025: sentinel pattern in *_copy_with.dart files is a false-positive.
// Pattern: `identifier != null ? identifier() : this.identifier`
// This is a single-level ternary implementing nullable-field sentinel, not a
// true nested ternary. Allowlisted to suppress SonarCloud S3358 false alarm.
final _sentinelCopyWithPattern = RegExp(
  r'[\w$]+\s*!=\s*null\s*\?\s*[\w$]+\(\)\s*:\s*this\.[\w$]+',
);

bool _isSentinelCopyWithFile(String file) => file.endsWith('_copy_with.dart');

void _checkNestedTernaries(
  String file,
  List<String> lines,
  List<String> violations,
) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    // Skip comment lines — type notation in docs (e.g. `T? Function()?`) is
    // not a ternary operator.
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
    // ADR-025: skip sentinel copyWith pattern in *_copy_with.dart files.
    if (_isSentinelCopyWithFile(file) &&
        _sentinelCopyWithPattern.hasMatch(line)) {
      continue;
    }
    // Ternary `?` is always preceded by a space (dart format guarantees this).
    // Type-annotation `?` follows a type name directly (no space before `?`).
    // Counting only space-prefixed `?` avoids false positives on nullable
    // parameter declarations and method signatures.
    final ternaryCount = RegExp(r' \?(?!\?|\.)').allMatches(line).length;
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

// ── Golden integrity check (--check-goldens) ───────────────────────────────

/// Detects byte-identical light/dark golden pairs — a sign that
/// [captureScreenshot] captured a solid-color loading frame instead of real
/// screen content (issue #203).
///
/// Groups PNGs by `{screen}_{locale}_{device}` key (strips `_light_` / `_dark_`),
/// then compares raw bytes. Returns exit code: 0 = pass, 1 = violations found.
Future<int> _checkGoldenIdenticalPairs(String goldenDir) async {
  final dir = Directory(goldenDir);
  if (!dir.existsSync()) {
    print('Golden directory not found: $goldenDir — skipping.');
    return 0;
  }

  // key = "{screen}_{locale}_{device}" → {"light": File, "dark": File}
  final pairs = <String, Map<String, File>>{};

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.png')) continue;

    final base = name.substring(0, name.length - 4); // strip .png
    // Pattern: {screen_and_locale}_{light|dark}_{device_id}
    // Examples: chat_thread_nl_NL_light_ios_67
    //           home_buyer_en_US_dark_android_phone
    final match = RegExp(r'^(.+?)_(light|dark)_(.+)$').firstMatch(base);
    if (match == null) continue;

    final key = '${match.group(1)!}_${match.group(3)!}';
    final theme = match.group(2)!;
    (pairs[key] ??= {})[theme] = entity;
  }

  var violations = 0;

  for (final entry in pairs.entries) {
    final lightFile = entry.value['light'];
    final darkFile = entry.value['dark'];
    if (lightFile == null || darkFile == null) continue;

    final lightBytes = lightFile.readAsBytesSync();
    final darkBytes = darkFile.readAsBytesSync();

    if (lightBytes.length == darkBytes.length &&
        _bytesEqual(lightBytes, darkBytes)) {
      stderr.writeln(
        'IDENTICAL GOLDEN PAIR: ${entry.key}\n'
        '  light: ${lightFile.path}\n'
        '  dark:  ${darkFile.path}\n'
        '  Size: ${lightBytes.length} bytes each — solid-color capture suspected.',
      );
      violations++;
    }
  }

  if (violations > 0) {
    stderr.writeln(
      '\n$violations identical light/dark pair(s) found.\n'
      'These are pre-existing failures from issue #203 (captureScreenshot\n'
      'pre-paint capture for async-built screens). The actual pump-sequence\n'
      'fix is tracked in #203 — this gate only inventories the affected\n'
      'pairs. Run with: dart run scripts/check_quality.dart --check-goldens',
    );
    return 1;
  }

  print(
    'Golden integrity check passed — all light/dark pairs are distinct '
    '(${pairs.length} pairs checked).',
  );
  return 0;
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
