#!/usr/bin/env dart
// ignore_for_file: avoid_print

// B-60: License compliance check + dependency manifest emission.
//
// Replaces the previous heuristic GPL/AGPL grep on `pubspec.lock` (which
// missed transitive GPL via native deps and dual-licensed packages) with
// `pana`-driven license analysis backed by a curated allowlist.
//
// Tier-1 retrospective B-60.
//
// Usage:
//   dart run scripts/check_dependencies_pana.dart                  # strict (CI default — requires pana)
//   dart run scripts/check_dependencies_pana.dart --allow-unknown  # lenient (local dev — pana optional)
//   dart run scripts/check_dependencies_pana.dart --emit-manifest  # + write deps-manifest.json
//   dart run scripts/check_dependencies_pana.dart --json           # machine-readable result
//
// Allowlist format: `LICENSES.allowlist` at repo root, one package per line:
//   {package_name}:{spdx_license_id}:{rationale}
// Lines starting with `#` are comments.
//
// Exit codes:
//   0  All licenses cleared (or only allowlisted exceptions)
//   1  At least one disallowed license found OR an unknown license without
//      --allow-unknown (fail-closed default)
//   2  Tooling failure (pana not installed in strict mode, pubspec.lock
//      missing, etc.)

import 'dart:convert';
import 'dart:io';

/// SPDX-prefix tokens that are disallowed. Comparisons normalise to
/// lowercase + strip suffixes (`-only`, `-or-later`) before matching, so
/// `gpl-3.0` matches but `lgpl-3.0` does NOT (closes gemini's lgpl
/// false-positive finding on PR #267).
const _disallowedSpdxPrefixes = <String>{
  'gpl-2.0',
  'gpl-3.0',
  'agpl-3.0',
  'cc-by-nc',
  'sspl-1.0',
  // Plain "gpl" / "agpl" tokens for non-SPDX-formatted reports (defensive)
  'gpl',
  'agpl',
};

/// Tokens that should explicitly NOT match the disallowed list even though
/// they share substring with `gpl`/`agpl`. LGPL is OSI-approved + business-
/// friendly; we do not block it.
const _exemptSpdxPrefixes = <String>{
  'lgpl-2.0',
  'lgpl-2.1',
  'lgpl-3.0',
  'lgpl', // bare token form
};

const _allowlistPath = 'LICENSES.allowlist';
const _manifestOutPath = 'build/deps-manifest.json';

class _AllowEntry {
  _AllowEntry(this.package, this.license, this.rationale);
  final String package;
  final String license;
  final String rationale;
}

void main(List<String> args) async {
  final emitManifest = args.contains('--emit-manifest');
  final jsonOutput = args.contains('--json');
  final allowUnknown = args.contains('--allow-unknown');

  // 1. Verify pubspec.lock exists
  final lockfile = File('pubspec.lock');
  if (!lockfile.existsSync()) {
    _stderr('pubspec.lock not found — run `flutter pub get` first.');
    exit(2);
  }

  // 2. Load allowlist
  final allowlist = _loadAllowlist();

  // 3. Run pana. In strict mode (default), pana is required — if it's
  //    not installed or fails, exit 2 (tooling failure). In lenient
  //    mode (`--allow-unknown`), pana is optional and we degrade to
  //    license=unknown without failing.
  //
  //    Closes gemini's PR #267 security-HIGH finding: previous behaviour
  //    silently passed every package when pana was unavailable, defeating
  //    the entire check.
  final panaJson = await _tryRunPana();
  if (panaJson == null && !allowUnknown) {
    _stderr(
      'pana is required for license analysis but is unavailable. Install '
      'via `dart pub global activate pana` or pre-cache it in CI. To run '
      'a degraded check that allows unknown licenses (NOT recommended in '
      'CI), pass --allow-unknown.',
    );
    exit(2);
  }
  final lockEntries = _parsePubspecLock(lockfile.readAsStringSync());

  // 4. Build a license map (package -> license string)
  // Prefer pana output when available; fall back to "unknown" otherwise.
  final licenseMap = <String, String>{};
  if (panaJson != null) {
    licenseMap.addAll(_extractLicensesFromPana(panaJson));
  }
  for (final entry in lockEntries.keys) {
    licenseMap.putIfAbsent(entry, () => 'unknown');
  }

  // 5. Classify each dependency
  final findings = <Map<String, String>>[];
  for (final entry in licenseMap.entries) {
    final pkg = entry.key;
    final license = entry.value;

    final classification = _classify(license, pkg, allowUnknown);
    if (classification == _Status.allowed) continue;

    final allowed = allowlist[pkg];
    if (allowed != null) {
      findings.add({
        'package': pkg,
        'license': license,
        'status': 'allowlisted',
        'rationale': allowed.rationale,
      });
      continue;
    }

    findings.add({
      'package': pkg,
      'license': license,
      'status': 'BLOCKED',
      'rationale':
          classification == _Status.unknown
              ? 'License unknown — fail-closed (use --allow-unknown to override)'
              : 'No entry in $_allowlistPath',
    });
  }

  // 6. Emit deps manifest if requested (placeholder for full SPDX SBOM)
  // TODO: upgrade to SPDX 2.3 JSON output when a Dart-side generator
  // matures. For now this is a project-local manifest format documenting
  // every direct + transitive dep with its resolved version + license
  // (when known). Suitable for App Review §5.1.6 disclosure when paired
  // with the explicit SDK declarations in privacy_details.yaml.
  if (emitManifest) {
    final outFile = File(_manifestOutPath);
    outFile.parent.createSync(recursive: true);
    final manifest = {
      'schema': 'deelmarkt-deps-manifest@1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'pana_available': panaJson != null,
      'pubspec_lock_resolved_count': lockEntries.length,
      'dependencies':
          lockEntries.entries.map((e) {
            return {
              'name': e.key,
              'version': e.value,
              'license': licenseMap[e.key] ?? 'unknown',
              'allowlisted': allowlist.containsKey(e.key),
            };
          }).toList(),
    };
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    _stderr('Wrote $_manifestOutPath (${lockEntries.length} packages).');
  }

  // 7. Report
  final blocked = findings.where((f) => f['status'] == 'BLOCKED').toList();
  final allowed = findings.where((f) => f['status'] == 'allowlisted').toList();

  if (jsonOutput) {
    print(
      const JsonEncoder.withIndent('  ').convert({
        'total_packages': lockEntries.length,
        'pana_available': panaJson != null,
        'allow_unknown_mode': allowUnknown,
        'allowlist_size': allowlist.length,
        'blocked': blocked,
        'allowlisted': allowed,
      }),
    );
  } else {
    print('License check — ${lockEntries.length} packages scanned');
    print('  pana available: ${panaJson != null}');
    print('  allow-unknown mode: $allowUnknown');
    if (allowed.isNotEmpty) {
      print('  ${allowed.length} allowlisted exception(s):');
      for (final f in allowed) {
        print('    - ${f['package']} (${f['license']}) — ${f['rationale']}');
      }
    }
    if (blocked.isNotEmpty) {
      print('  ${blocked.length} BLOCKED package(s):');
      for (final f in blocked) {
        print('    ✗ ${f['package']} (${f['license']}) — ${f['rationale']}');
      }
    } else {
      print('  ✓ No disallowed licenses found.');
    }
  }

  if (blocked.isNotEmpty) {
    _stderr(
      '\nFAILED: ${blocked.length} package(s) require attention. Either '
      'remove the dependency, add an explicit allowlist entry with a '
      'rationale in $_allowlistPath, or (for unknown licenses only) '
      'pass --allow-unknown if running locally.',
    );
    exit(1);
  }

  exit(0);
}

enum _Status { allowed, disallowed, unknown }

/// SPDX-aware license classification with LGPL exemption.
///
/// Closes gemini's PR #267 security-HIGH finding by:
/// 1. Distinguishing GPL (blocked) from LGPL (allowed) via prefix tokens
///    rather than substring `contains`.
/// 2. Treating `unknown` as fail-closed in strict mode (returns
///    [_Status.unknown] which the caller blocks unless --allow-unknown).
/// 3. Continuing to check the package name against banned tokens for the
///    edge case of pana returning an unrecognised license but the package
///    name itself indicating GPL (e.g. `gpl_utils`).
_Status _classify(String license, String pkgName, bool allowUnknown) {
  final lower = license.toLowerCase().trim();
  if (lower.isEmpty || lower == 'unknown' || lower == 'unrecognised') {
    // Defensive package-name check (gemini's `gpl_utils` example): even
    // when pana cannot determine the license, a package literally named
    // "gpl_*" is still suspect and must not pass silently.
    final pkgLower = pkgName.toLowerCase();
    final pkgImpliesBan = _disallowedSpdxPrefixes.any(
      (t) => pkgLower.contains(t.split('-').first),
    );
    if (pkgImpliesBan) return _Status.disallowed;
    return allowUnknown ? _Status.allowed : _Status.unknown;
  }

  // Normalise SPDX suffixes so `gpl-3.0-or-later` matches `gpl-3.0`.
  final normalised = lower.replaceAll('-only', '').replaceAll('-or-later', '');

  // Exemption first (LGPL is OSI-approved, business-friendly).
  if (_exemptSpdxPrefixes.any(normalised.startsWith)) return _Status.allowed;

  if (_disallowedSpdxPrefixes.any(normalised.startsWith)) {
    return _Status.disallowed;
  }
  return _Status.allowed;
}

void _stderr(String msg) => stderr.writeln(msg);

Map<String, _AllowEntry> _loadAllowlist() {
  final file = File(_allowlistPath);
  if (!file.existsSync()) {
    return const {};
  }
  final entries = <String, _AllowEntry>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(':');
    if (parts.length < 3) {
      _stderr('  ⚠ malformed allowlist entry: "$line"');
      continue;
    }
    final pkg = parts[0].trim();
    final license = parts[1].trim();
    final rationale = parts.sublist(2).join(':').trim();
    entries[pkg] = _AllowEntry(pkg, license, rationale);
  }
  return entries;
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
Future<dynamic> _tryRunPana() async {
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
Map<String, String> _extractLicensesFromPana(dynamic panaJson) {
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

/// Minimal pubspec.lock parser. We only need the package name + version;
/// avoid pulling `yaml` package as a runtime dep.
///
/// Per gemini's PR #267 medium finding: prefer comment-strip + substring
/// over quote-aware regex. Implementation below splits on `version:` and
/// strips quotes, which is simpler and tolerates a wider range of YAML
/// emitter quirks (single-quoted, double-quoted, unquoted versions).
Map<String, String> _parsePubspecLock(String content) {
  final out = <String, String>{};
  final lines = content.split('\n');
  String? currentPkg;
  String? currentVersion;
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
        if (currentPkg != null && currentVersion != null) {
          out[currentPkg] = currentVersion;
        }
        currentPkg = candidate;
        currentVersion = null;
        continue;
      }
    }

    // Version inside package block: 4-space indent + `version:` prefix.
    // Substring + split + quote-strip rather than regex (gemini's note).
    if (indent == 4 && body.startsWith('version:') && currentPkg != null) {
      var value = body.substring('version:'.length).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      if (value.isNotEmpty) {
        currentVersion = value;
      }
    }
  }
  if (currentPkg != null && currentVersion != null) {
    out[currentPkg] = currentVersion;
  }
  return out;
}

int _leadingSpaces(String s) {
  var n = 0;
  while (n < s.length && s.codeUnitAt(n) == 0x20) {
    n += 1;
  }
  return n;
}
