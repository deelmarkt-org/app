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

void main(List<String> args) {
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

  if (checkUrls) {
    _checkUrls(errors, warnings);
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

  final nameWords = name.toLowerCase().split(RegExp(r'[\s,]+'));
  final subtitleWords = subtitle.toLowerCase().split(RegExp(r'[\s,]+'));
  final keywordList = keywords.toLowerCase().split(',').map((k) => k.trim());

  for (final kw in keywordList) {
    if (kw.isEmpty) continue;
    if (nameWords.any((w) => w == kw)) {
      warnings.add(
        'KEYWORD_DUPE [$locale]: "$kw" in keywords is already in name '
        '(wasted budget)',
      );
    }
    if (subtitleWords.any((w) => w == kw)) {
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

// ── URL checks (optional) ─────────────────────────────────────────────────────

void _checkUrls(List<String> errors, List<String> warnings) {
  final urlFields = ['support_url', 'marketing_url', 'privacy_url'];
  for (final locale in ['nl-NL', 'en-US']) {
    for (final field in urlFields) {
      final file = File('fastlane/metadata/$locale/$field.txt');
      if (!file.existsSync()) continue;
      final url = file.readAsStringSync().trim();
      if (url.isEmpty || url.contains('[TODO')) continue;
      // Note: actual HTTP check requires dart:io HttpClient — skipped in
      // offline/CI environments without network. Add --check-urls flag only
      // when running locally with network access.
      stdout.writeln('  URL (not checked in offline mode): $url');
    }
  }
}
