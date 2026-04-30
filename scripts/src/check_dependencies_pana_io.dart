// ignore_for_file: avoid_print

// I/O helpers for `check_dependencies_pana.dart` — pana invocation and
// pubspec.lock parsing. Extracted per Mahmutkaya's PR #267 review feedback
// to keep the main script focused on classification + verdict emission.

import 'dart:convert';
import 'dart:io';

class LockEntry {
  const LockEntry(this.version, this.source);

  /// Resolved version, e.g. `1.2.3`.
  final String version;

  /// Pubspec.lock `source:` field — `hosted`, `path`, `git`, or `sdk`.
  /// Non-`hosted` sources are first-party / SDK-shipped deps where pana
  /// cannot reasonably resolve a license; we treat unknown licenses on
  /// those as allowed. Only `hosted` packages with unknown licenses
  /// are subject to fail-closed strict mode.
  final String source;

  bool get isHosted => source == 'hosted';
}

/// Run `pana` to extract per-package license data.
///
/// Returns the decoded JSON or null if pana cannot be made available.
/// The caller decides whether null is fail-closed (strict mode) or
/// fail-open (--allow-unknown).
///
/// Activation is gated on a presence check (gemini's PR #267 medium
/// finding): we skip the network round-trip of `dart pub global activate
/// pana` if pana is already on the global path. CI can pre-install pana
/// in setup-flutter to short-circuit even the presence check.
Future<dynamic> tryRunPana() async {
  try {
    if (!await _isPanaInstalled()) {
      // Activate is idempotent but performs a network request. Only run
      // when pana is absent; CI environments should pre-cache.
      final activate = await Process.run('dart', [
        'pub',
        'global',
        'activate',
        'pana',
      ]);
      if (activate.exitCode != 0) return null;
    }
    final result = await Process.run('dart', [
      'pub',
      'global',
      'run',
      'pana',
      '--no-warning',
      '--json',
      '.',
    ]);
    if (result.exitCode != 0) return null;
    final stdout = result.stdout as String;
    return jsonDecode(stdout);
  } on Exception {
    return null;
  }
}

/// Cheap presence check that avoids the activation network round-trip.
Future<bool> _isPanaInstalled() async {
  try {
    final result = await Process.run('dart', ['pub', 'global', 'list']);
    if (result.exitCode != 0) return false;
    return (result.stdout as String).contains('pana ');
  } on Exception {
    return false;
  }
}

/// Pana JSON output schema is unstable across versions. We tolerate
/// missing keys by defaulting to "unknown" — the strict-mode caller
/// then fails closed on those.
Map<String, String> extractLicensesFromPana(dynamic panaJson) {
  final out = <String, String>{};
  try {
    final pkgs = (panaJson as Map<String, dynamic>)['packages'] as List?;
    if (pkgs == null) return out;
    for (final p in pkgs) {
      if (p is! Map) continue;
      final name = p['name'] as String?;
      final license = p['license'] as String? ?? 'unknown';
      if (name != null) out[name] = license;
    }
  } on Exception {
    // Schema drift — fall through.
  } on TypeError {
    // Cast failures from unexpected JSON shape — fall through.
  }
  return out;
}

/// Minimal pubspec.lock parser. Returns `package -> (version, source)`
/// per entry. Source classification (`hosted` / `path` / `git` / `sdk`)
/// distinguishes pub.dev deps from first-party / SDK-shipped deps and
/// is consumed by the strict-mode classifier.
///
/// Per gemini's PR #267 medium finding: prefer comment-strip + substring
/// over quote-aware regex. Implementation below splits on `version:` /
/// `source:` and strips quotes, which is simpler and tolerates a wider
/// range of YAML emitter quirks (single-quoted, double-quoted, unquoted).
Map<String, LockEntry> parsePubspecLock(String content) {
  final out = <String, LockEntry>{};
  final lines = content.split('\n');
  String? currentPkg;
  String? currentVersion;
  String? currentSource;

  void flush() {
    final pkg = currentPkg;
    final version = currentVersion;
    if (pkg != null && version != null) {
      out[pkg] = LockEntry(version, currentSource ?? 'hosted');
    }
  }

  for (final raw in lines) {
    final line = raw.trimRight();

    // Strip trailing comments (`# ...`) before further parsing — matches
    // gemini's suggestion. We deliberately do NOT strip leading whitespace
    // because YAML structure is whitespace-sensitive and we use indentation
    // depth to distinguish top-level package entries from nested fields.
    final commentIdx = line.indexOf('#');
    final stripped = commentIdx >= 0 ? line.substring(0, commentIdx) : line;
    final indent = _leadingSpaces(stripped);
    final body = stripped.trimLeft();

    // Top-level package entry: 2-space indent + `package_name:` + nothing else
    if (indent == 2 && body.endsWith(':')) {
      final candidate = body.substring(0, body.length - 1);
      if (RegExp(r'^[a-z0-9_]+$').hasMatch(candidate)) {
        flush();
        currentPkg = candidate;
        currentVersion = null;
        currentSource = null;
        continue;
      }
    }

    // Field inside package block: 4-space indent + `key:` prefix.
    if (indent == 4 && currentPkg != null) {
      if (body.startsWith('version:')) {
        final v = _stripQuotes(body.substring('version:'.length).trim());
        if (v.isNotEmpty) currentVersion = v;
      } else if (body.startsWith('source:')) {
        final v = _stripQuotes(body.substring('source:'.length).trim());
        if (v.isNotEmpty) currentSource = v;
      }
    }
  }
  flush();
  return out;
}

String _stripQuotes(String value) {
  final trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

int _leadingSpaces(String s) {
  var n = 0;
  while (n < s.length && s.codeUnitAt(n) == 0x20) {
    n += 1;
  }
  return n;
}
