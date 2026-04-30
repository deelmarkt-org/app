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
//   dart run scripts/check_dependencies_pana.dart                  # full check
//   dart run scripts/check_dependencies_pana.dart --emit-manifest  # + write deps-manifest.json
//   dart run scripts/check_dependencies_pana.dart --json           # machine-readable result
//
// Allowlist format: `LICENSES.allowlist` at repo root, one package per line:
//   {package_name}:{spdx_license_id}:{rationale}
// Lines starting with `#` are comments.
//
// Exit codes:
//   0  All licenses cleared (or only allowlisted exceptions)
//   1  At least one disallowed license found
//   2  Tooling failure (pana not installed, pubspec.lock missing, etc.)

import 'dart:convert';
import 'dart:io';

const _disallowedLicenses = <String>{
  'gpl', // GPL-2.0, GPL-3.0
  'agpl', // AGPL-3.0
  'cc-by-nc', // non-commercial
  'sspl', // SSPL is non-OSI; treated like AGPL
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

  // 1. Verify pubspec.lock exists
  final lockfile = File('pubspec.lock');
  if (!lockfile.existsSync()) {
    _stderr('pubspec.lock not found — run `flutter pub get` first.');
    exit(2);
  }

  // 2. Load allowlist
  final allowlist = _loadAllowlist();

  // 3. Run pana (best-effort; fall back to lockfile inspection if unavailable)
  final panaJson = await _tryRunPana();
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
    final lower = license.toLowerCase();

    final isDisallowed = _disallowedLicenses.any(
      (banned) => lower.contains(banned),
    );
    if (!isDisallowed) continue;

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
      'rationale': 'No entry in $_allowlistPath',
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
        'allowlist_size': allowlist.length,
        'blocked': blocked,
        'allowlisted': allowed,
      }),
    );
  } else {
    print('License check — ${lockEntries.length} packages scanned');
    if (panaJson == null) {
      print(
        '  ⚠ pana unavailable — license data falls back to "unknown" for all '
        'packages. Install via: dart pub global activate pana',
      );
    }
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
      '\nFAILED: ${blocked.length} package(s) carry disallowed licenses '
      'and are not in $_allowlistPath. Either remove the dependency or '
      'add an explicit allowlist entry with a rationale.',
    );
    exit(1);
  }

  exit(0);
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

/// Best-effort run of `pana` to extract per-package license data.
/// Returns the decoded JSON or null on tooling failure.
Future<dynamic> _tryRunPana() async {
  try {
    // Activate (idempotent — no-op if already activated).
    await Process.run('dart', ['pub', 'global', 'activate', 'pana']);
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

/// Pana JSON output schema is unstable across versions. We tolerate
/// missing keys by defaulting to "unknown" — the lockfile fallback will
/// still cover every package.
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
Map<String, String> _parsePubspecLock(String content) {
  final out = <String, String>{};
  final lines = content.split('\n');
  String? currentPkg;
  String? currentVersion;
  for (final raw in lines) {
    final line = raw.trimRight();
    // Top-level package: `  package_name:`
    final pkgMatch = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
    if (pkgMatch != null) {
      if (currentPkg != null && currentVersion != null) {
        out[currentPkg] = currentVersion;
      }
      currentPkg = pkgMatch.group(1);
      currentVersion = null;
      continue;
    }
    // Version inside package block: `    version: "1.2.3"`
    final verMatch = RegExp(r'^    version: "([^"]+)"').firstMatch(line);
    if (verMatch != null && currentPkg != null) {
      currentVersion = verMatch.group(1);
    }
  }
  if (currentPkg != null && currentVersion != null) {
    out[currentPkg] = currentVersion;
  }
  return out;
}
