// ignore_for_file: avoid_print

// I/O helpers for `check_dependencies_pana.dart` — pana invocation,
// pub-cache LICENSE-file scanning, and pubspec.lock parsing. Extracted
// per Mahmutkaya's PR #267 review feedback to keep the main script
// focused on classification + verdict emission.

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

/// Pana analyzes a single package (the project), not transitive deps —
/// its JSON output exposes the root project's license under
/// `report.sections[].licenses[]`, but does NOT enumerate per-dependency
/// licenses. The first iteration of this script assumed pana would
/// return a `packages[]` array; CI revealed every transitive dep was
/// reported as "unknown" because that array does not exist. Tolerated
/// here for backward compatibility — returns the root project's
/// license if pana surfaces it; otherwise an empty map. Per-dep
/// licenses come from [scanPubCacheLicenses].
Map<String, String> extractLicensesFromPana(dynamic panaJson) {
  final out = <String, String>{};
  try {
    final root = panaJson as Map<String, dynamic>;
    // Root-package shape (pana 0.22+): { "report": { "sections": [...] } }
    // — license appears under a section with `id == "license"` whose
    // grantedPoints / summary mention the SPDX identifier. We do NOT
    // attempt to mine that here because it is unreliable across pana
    // versions; callers should treat pana as advisory only.
    // For backward-compat: also accept the legacy `packages[]` shape if
    // a future pana variant produces it.
    final pkgs = root['packages'] as List?;
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

/// Per-dependency license extraction by reading each hosted package's
/// LICENSE file out of pub-cache and matching its content against a
/// curated SPDX detector.
///
/// Why this and not pana: pana analyzes the root project only. The
/// previous implementation called `pana --json .` and attempted to read
/// a `packages[]` array that never exists for a single-package run, so
/// every transitive dep landed as `unknown` and the strict-mode CI gate
/// blocked every PR. This scanner walks `pubspec.lock` instead, finds
/// each `hosted` dep at `<pub-cache>/hosted/pub.dev/<name>-<version>/`
/// (override via `PUB_CACHE` env), and reads `LICENSE` (or one of the
/// common variants — `LICENSE.md`, `LICENSE.txt`, `COPYING`).
///
/// SPDX detection is deliberately conservative: we only emit a
/// confident SPDX identifier when the LICENSE text contains an
/// unambiguous fingerprint (e.g. "Permission is hereby granted, free
/// of charge" → MIT; "Apache License" + "Version 2.0" → Apache-2.0).
/// Ambiguous LICENSE files surface as `unknown` and the caller's
/// strict mode handles them per the existing `LICENSES.allowlist`
/// escape hatch.
Map<String, String> scanPubCacheLicenses(Map<String, LockEntry> lockEntries) {
  final out = <String, String>{};
  final cacheRoot = _resolvePubCacheRoot();
  if (cacheRoot == null) return out;

  final hostedRoot = Directory('$cacheRoot/hosted/pub.dev');
  if (!hostedRoot.existsSync()) {
    // Some CI runners cache hosted packages under hosted/<host>/ where
    // <host> is not pub.dev. Walk siblings of pub.dev as a fallback.
    final hostedParent = Directory('$cacheRoot/hosted');
    if (!hostedParent.existsSync()) return out;
    for (final host in hostedParent.listSync().whereType<Directory>()) {
      _scanHostedRoot(host, lockEntries, out);
    }
    return out;
  }
  _scanHostedRoot(hostedRoot, lockEntries, out);
  return out;
}

void _scanHostedRoot(
  Directory hostedRoot,
  Map<String, LockEntry> lockEntries,
  Map<String, String> out,
) {
  for (final entry in lockEntries.entries) {
    final name = entry.key;
    final lock = entry.value;
    if (!lock.isHosted) continue;
    if (out.containsKey(name)) continue;

    final pkgDir = Directory('${hostedRoot.path}/$name-${lock.version}');
    if (!pkgDir.existsSync()) continue;

    final spdx = _detectSpdxFromPackageDir(pkgDir);
    if (spdx != null) out[name] = spdx;
  }
}

String? _resolvePubCacheRoot() {
  // Honour the standard `PUB_CACHE` env var first (used by both Dart
  // tooling and `actions/setup-flutter`).
  final fromEnv = Platform.environment['PUB_CACHE'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    if (Directory(fromEnv).existsSync()) return fromEnv;
  }
  // Platform defaults — Dart docs:
  //   * Windows → %LOCALAPPDATA%\Pub\Cache (or %APPDATA%\Pub\Cache)
  //   * macOS / Linux → $HOME/.pub-cache
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final candidate = '$localAppData\\Pub\\Cache';
      if (Directory(candidate).existsSync()) return candidate;
    }
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      final candidate = '$appData\\Pub\\Cache';
      if (Directory(candidate).existsSync()) return candidate;
    }
  } else {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final candidate = '$home/.pub-cache';
      if (Directory(candidate).existsSync()) return candidate;
    }
  }
  return null;
}

String? _detectSpdxFromPackageDir(Directory pkgDir) {
  for (final fileName in const [
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'License',
    'License.md',
    'License.txt',
    'COPYING',
    'COPYING.md',
    'COPYING.txt',
  ]) {
    final f = File('${pkgDir.path}/$fileName');
    if (f.existsSync()) {
      final content = f.readAsStringSync();
      final spdx = detectSpdxFromLicenseText(content);
      if (spdx != null) return spdx;
    }
  }
  return null;
}

/// SPDX detection from a LICENSE text body. Public for testing.
///
/// Order matters here in a non-obvious way: a LICENSE genuinely under
/// MPL-2.0 (or Apache-2.0, etc.) **mentions** GPL/AGPL/LGPL inside its
/// "Secondary License" / compatibility boilerplate — the `gtk` Dart
/// package is a real-world example. If we scanned for GPL-family
/// substrings first, every MPL package would be mis-classified as
/// AGPL. So permissive license headers MUST be matched before the
/// GPL family fallback. Within the GPL family itself, LGPL (and AGPL)
/// MUST come before bare GPL because of the substring overlap —
/// gemini's PR #267 finding regression.
/// Conservative by design: ambiguous files return `null` and the
/// caller treats them as `unknown` (fail-closed in strict mode unless
/// an explicit `LICENSES.allowlist` entry exists).
String? detectSpdxFromLicenseText(String text) {
  // Normalise: lowercase, collapse runs of whitespace so multi-line
  // license boilerplate matches single-line markers.
  final n = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // --- 1. Permissive license headers first ---
  // These have stable opening text that is unambiguous and avoids
  // the false-positives that come from "Secondary License" boilerplate.

  // MPL 2.0 — header is a distinctive single line.
  if (n.contains('mozilla public license') && n.contains('version 2.0')) {
    return 'MPL-2.0';
  }
  // Apache 2.0 has a stable preamble.
  if (n.contains('apache license') && n.contains('version 2.0')) {
    return 'Apache-2.0';
  }
  // BSD: 2-clause vs 3-clause is distinguishable by the
  // "neither the name of … nor the names of its contributors" clause.
  if (n.contains('redistribution and use in source and binary forms')) {
    if (n.contains('neither the name of') || n.contains('endorse or promote')) {
      return 'BSD-3-Clause';
    }
    return 'BSD-2-Clause';
  }
  // MIT: distinctive opening sentence.
  if (n.contains('permission is hereby granted, free of charge') &&
      n.contains('without restriction')) {
    return 'MIT';
  }
  // ISC: similar to MIT but with a different opening clause.
  if (n.contains('permission to use, copy, modify, and/or distribute')) {
    return 'ISC';
  }
  // Unlicense / public-domain.
  if (n.contains('this is free and unencumbered software released into') &&
      n.contains('public domain')) {
    return 'Unlicense';
  }
  if (n.contains('cc0 1.0 universal') || n.contains('creative commons cc0')) {
    return 'CC0-1.0';
  }
  // BSD without the 2/3-clause discriminator (rare).
  if (n.contains('bsd license')) return 'BSD-3-Clause';

  // --- 2. Disallowed-license fallbacks ---
  // Reaching this branch means no permissive header matched, so a
  // genuine GPL/AGPL/LGPL/SSPL/CC-BY-NC declaration is almost
  // certainly the actual license. LGPL/AGPL must come before bare
  // GPL (substring overlap).

  if (n.contains('gnu affero general public license')) return 'AGPL-3.0';
  if (n.contains('gnu lesser general public license')) {
    if (n.contains('version 2.1')) return 'LGPL-2.1';
    if (n.contains('version 3')) return 'LGPL-3.0';
    return 'LGPL-2.1';
  }
  if (n.contains('gnu general public license')) {
    if (n.contains('version 3')) return 'GPL-3.0';
    if (n.contains('version 2')) return 'GPL-2.0';
    return 'GPL-3.0';
  }
  if (n.contains('server side public license')) return 'SSPL-1.0';
  if (n.contains('creative commons') &&
      (n.contains('non-commercial') || n.contains('noncommercial'))) {
    return 'CC-BY-NC-4.0';
  }

  return null;
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
