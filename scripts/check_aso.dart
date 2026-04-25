#!/usr/bin/env dart
// check_aso.dart
//
// Validates ASO copy files for:
//   1. Character budget compliance (per App Store / Play Console limits)
//   2. No placeholder text (TODO markers)
//   3. No forbidden terms (competitor names, policy-trigger words)
//   4. URL reachability (optional — pass --check-urls to enable)
//   5. Keyword de-duplication across name + subtitle + keywords fields
//   6. Locale parity — every file must exist in both nl-NL and en-US
//
// Usage:
//   dart run scripts/check_aso.dart
//   dart run scripts/check_aso.dart --check-urls
//   dart run scripts/check_aso.dart --verbose
//
// Exit codes:
//   0  All checks passed
//   1  One or more checks failed

import 'dart:io';

// ── Character budgets ────────────────────────────────────────────────────────

const _iosBudgets = {
  'name': 30,
  'subtitle': 30,
  'keywords': 100,
  'promotional_text': 170,
  'description': 4000,
  'release_notes': 4000,
};

const _androidBudgets = {
  'title': 30,
  'short_description': 80,
  'full_description': 4000,
};

// ── Forbidden terms ──────────────────────────────────────────────────────────
// Competitor names trigger App Store Review §2.3.2.
// Superlatives without proof trigger §2.3.2 rejection.
const _forbiddenTerms = [
  '#1',
  'number one',
  'nummer 1',
  'best app',
  'beste app',
  'marktplaats.nl',
  'vinted',
  'facebook marketplace',
  'ebay',
  'amazon',
];

// ── Main ─────────────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final checkUrls = args.contains('--check-urls');
  final verbose = args.contains('--verbose');
  final errors = <String>[];
  final warnings = <String>[];

  _checkIosLocale('nl-NL', errors, warnings, verbose: verbose);
  _checkIosLocale('en-US', errors, warnings, verbose: verbose);
  _checkAndroidLocale('nl-NL', errors, warnings, verbose: verbose);
  _checkAndroidLocale('en-US', errors, warnings, verbose: verbose);
  _checkLocaleParity(errors);
  _checkKeywordDeduplication('nl-NL', errors, warnings);
  _checkKeywordDeduplication('en-US', errors, warnings);
  _checkReviewInformation(errors);

  if (checkUrls) {
    await _checkUrls(errors, warnings);
  }

  // ── Report ─────────────────────────────────────────────────────────────────
  if (warnings.isNotEmpty) {
    stderr.writeln('\n⚠️  Warnings (${warnings.length}):');
    for (final w in warnings) {
      stderr.writeln('  $w');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('\n❌  Errors (${errors.length}):');
    for (final e in errors) {
      stderr.writeln('  $e');
    }
    stderr.writeln('\nFix errors above before App Store submission.');
    exit(1);
  }

  stdout.writeln('✅  ASO copy checks passed.');
}

// ── iOS checks ────────────────────────────────────────────────────────────────

void _checkIosLocale(
  String locale,
  List<String> errors,
  List<String> warnings, {
  required bool verbose,
}) {
  final base = 'fastlane/metadata/$locale';
  for (final entry in _iosBudgets.entries) {
    final field = entry.key;
    final budget = entry.value;
    final file = File('$base/$field.txt');
    if (!file.existsSync()) {
      errors.add('MISSING: $base/$field.txt');
      continue;
    }
    final content = file.readAsStringSync().trim();
    if (content.isEmpty) {
      errors.add('EMPTY: $base/$field.txt');
      continue;
    }
    if (content.contains('[TODO')) {
      errors.add('PLACEHOLDER: $base/$field.txt still contains TODO marker');
    }
    if (content.length > budget) {
      errors.add(
        'OVER_BUDGET: $base/$field.txt is ${content.length} chars '
        '(limit $budget)',
      );
    } else if (verbose) {
      stdout.writeln('  ✓  $locale/$field — ${content.length}/$budget chars');
    }
    _checkForbiddenTerms('$base/$field.txt', content, errors);
  }
}

// ── Android checks ────────────────────────────────────────────────────────────

void _checkAndroidLocale(
  String locale,
  List<String> errors,
  List<String> warnings, {
  required bool verbose,
}) {
  final base = 'fastlane/android/metadata/$locale';
  for (final entry in _androidBudgets.entries) {
    final field = entry.key;
    final budget = entry.value;
    final file = File('$base/$field.txt');
    if (!file.existsSync()) {
      errors.add('MISSING: $base/$field.txt');
      continue;
    }
    final content = file.readAsStringSync().trim();
    if (content.isEmpty) {
      errors.add('EMPTY: $base/$field.txt');
      continue;
    }
    if (content.contains('[TODO')) {
      errors.add('PLACEHOLDER: $base/$field.txt still contains TODO marker');
    }
    if (content.length > budget) {
      errors.add(
        'OVER_BUDGET: $base/$field.txt is ${content.length} chars '
        '(limit $budget)',
      );
    } else if (verbose) {
      stdout.writeln(
        '  ✓  android/$locale/$field — ${content.length}/$budget chars',
      );
    }
    _checkForbiddenTerms('$base/$field.txt', content, errors);
  }
}

// ── Locale parity ─────────────────────────────────────────────────────────────

void _checkLocaleParity(List<String> errors) {
  for (final field in _iosBudgets.keys) {
    final nl = File('fastlane/metadata/nl-NL/$field.txt').existsSync();
    final en = File('fastlane/metadata/en-US/$field.txt').existsSync();
    if (nl != en) {
      errors.add(
        'PARITY: iOS $field.txt exists in ${nl ? "nl-NL" : ""} '
        'but not in ${en ? "" : "en-US"}',
      );
    }
  }
  for (final field in _androidBudgets.keys) {
    final nl = File('fastlane/android/metadata/nl-NL/$field.txt').existsSync();
    final en = File('fastlane/android/metadata/en-US/$field.txt').existsSync();
    if (nl != en) {
      errors.add(
        'PARITY: Android $field.txt exists in ${nl ? "nl-NL" : ""} '
        'but not in ${en ? "" : "en-US"}',
      );
    }
  }
}

// ── Keyword de-duplication ───────────────────────────────────────────────────

void _checkKeywordDeduplication(
  String locale,
  List<String> errors,
  List<String> warnings,
) {
  final name =
      File('fastlane/metadata/$locale/name.txt').readAsStringSync().trim();
  final subtitle =
      File('fastlane/metadata/$locale/subtitle.txt').readAsStringSync().trim();
  final keywords =
      File('fastlane/metadata/$locale/keywords.txt').readAsStringSync().trim();

  // Gemini MED: use whole-phrase regex instead of word-splitting so that
  // multi-word keywords (e.g. "safe marketplace") are correctly matched
  // against name/subtitle, not just their individual words.
  final nameLower = name.toLowerCase();
  final subtitleLower = subtitle.toLowerCase();
  final keywordList = keywords.toLowerCase().split(',').map((k) => k.trim());

  for (final kw in keywordList) {
    if (kw.isEmpty) continue;
    // Match kw as a whole word/phrase (word boundaries on both sides).
    final pattern = RegExp(r'(?<![a-z])' + RegExp.escape(kw) + r'(?![a-z])');
    if (pattern.hasMatch(nameLower)) {
      warnings.add(
        'KEYWORD_DUPE [$locale]: "$kw" in keywords is already in name '
        '(wasted budget)',
      );
    }
    if (pattern.hasMatch(subtitleLower)) {
      warnings.add(
        'KEYWORD_DUPE [$locale]: "$kw" in keywords is already in subtitle '
        '(wasted budget)',
      );
    }
  }
}

// ── Forbidden terms ───────────────────────────────────────────────────────────

void _checkForbiddenTerms(String path, String content, List<String> errors) {
  final lower = content.toLowerCase();
  for (final term in _forbiddenTerms) {
    if (lower.contains(term.toLowerCase())) {
      errors.add('FORBIDDEN_TERM: "$term" found in $path');
    }
  }
}

// ── Review information TODO check ────────────────────────────────────────────
// Errors when TestFlight review_information fields still contain [TODO]
// markers. Promoted from warning → error after GH #162 close-out: any TODO
// regression here would silently re-block the next TestFlight cut.
//
// Detected patterns (covers the three legal YAML quoting styles + a literal
// `[TODO]` in the per-field .txt mirrors):
//   first_name: "[TODO …]"   (double-quoted scalar)
//   last_name:  '[TODO …]'   (single-quoted scalar)
//   notes:      [TODO …]     (plain scalar, post-comment)
//   .txt files: any line starting with [TODO

void _checkReviewInformation(List<String> errors) {
  // Tests inject a tmp dir via ASO_REVIEW_INFO_DIR so the check can be
  // exercised in isolation. Production callers leave the env var unset.
  final baseDir =
      Platform.environment['ASO_REVIEW_INFO_DIR'] ??
      'fastlane/metadata/review_information';
  final yamlFile = File('$baseDir/privacy_details.yaml');
  if (yamlFile.existsSync()) {
    final content = yamlFile.readAsStringSync();
    // Strip comment lines so a documentation comment that mentions [TODO
    // (e.g. "do not commit values like [TODO]") never trips the check.
    final stripped = content
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('#'))
        .join('\n');
    final patterns = <RegExp>[
      RegExp(r'"(\[TODO[^"]*)"'), // double-quoted
      RegExp(r"'(\[TODO[^']*)'"), // single-quoted
      RegExp(r':\s*(\[TODO[^\n]*?)(?:\s*$)', multiLine: true), // plain scalar
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(stripped)) {
        errors.add(
          'REVIEW_INFO_TODO: privacy_details.yaml still contains TODO marker '
          '("${match.group(1)?.trim()}") — fill in before TestFlight '
          'submission. See docs/runbooks/RUNBOOK-appstore-reviewer.md.',
        );
      }
    }
  }

  // Per-field .txt mirrors that fastlane deliver actually transmits.
  const txtFields = [
    'email_address',
    'first_name',
    'last_name',
    'notes',
    'phone_number',
  ];
  for (final field in txtFields) {
    final txt = File('$baseDir/$field.txt');
    if (!txt.existsSync()) continue;
    final body = txt.readAsStringSync().trim();
    if (body.isEmpty) {
      errors.add(
        'REVIEW_INFO_EMPTY: '
        'fastlane/metadata/review_information/$field.txt is empty — '
        'fastlane deliver will fail. See '
        'docs/runbooks/RUNBOOK-appstore-reviewer.md.',
      );
      continue;
    }
    if (body.contains('[TODO')) {
      errors.add(
        'REVIEW_INFO_TODO: '
        'fastlane/metadata/review_information/$field.txt still contains '
        'TODO marker — fill in before TestFlight submission.',
      );
    }
  }
}

// ── URL checks (optional) ─────────────────────────────────────────────────────

// Gemini MED: implement actual HTTP HEAD request instead of a stub.
// Only invoked with --check-urls flag; requires network access.
Future<void> _checkUrls(List<String> errors, List<String> warnings) async {
  final urlFields = ['support_url', 'marketing_url', 'privacy_url'];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    for (final locale in ['nl-NL', 'en-US']) {
      for (final field in urlFields) {
        final file = File('fastlane/metadata/$locale/$field.txt');
        if (!file.existsSync()) continue;
        final url = file.readAsStringSync().trim();
        if (url.isEmpty || url.contains('[TODO')) continue;
        Uri uri;
        try {
          uri = Uri.parse(url);
        } on FormatException {
          errors.add('URL_INVALID [$locale/$field]: "$url" is not a valid URI');
          continue;
        }
        try {
          final request = await client.headUrl(uri);
          request.headers.set('User-Agent', 'check_aso.dart/1.0');
          final response = await request.close();
          await response.drain<void>();
          if (response.statusCode >= 400) {
            errors.add(
              'URL_UNREACHABLE [$locale/$field]: "$url" returned HTTP '
              '${response.statusCode}',
            );
          } else {
            stdout.writeln(
              '  URL OK [$locale/$field]: $url (HTTP ${response.statusCode})',
            );
          }
        } on SocketException catch (e) {
          errors.add(
            'URL_UNREACHABLE [$locale/$field]: "$url" — socket error: $e',
          );
        } on HttpException catch (e) {
          errors.add(
            'URL_UNREACHABLE [$locale/$field]: "$url" — HTTP error: $e',
          );
        }
      }
    }
  } finally {
    client.close();
  }
}
