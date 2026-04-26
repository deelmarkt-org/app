// Tests for the PERFORMANCE_FACADE check added by GH #222.
//
// ADR-027 §9 commits to a lint guard preventing features from importing
// firebase_performance / sentry_flutter tracer APIs directly — the facade
// in lib/core/services/performance/ is the SOLE entry point so the GDPR
// allowlist + Sentry/Firebase routing can never be bypassed.
//
// Strategy: spawn the real `dart run scripts/check_quality.dart <file>`
// against tmp Dart files placed at the path where they would live in
// production (lib/features/... vs lib/core/services/performance/...).
// We assert ONLY on the PERFORMANCE_FACADE line in stdout/stderr — other
// violations from the live repo or the tmp file's content are ignored.
//
// We use a tmp staging area UNDER the repo so the script's
// `file.startsWith('lib/')` predicate is honoured. Each test cleans up
// after itself.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory repoRoot;
  late Directory stagingDir;
  late String stagingRel;

  setUpAll(() {
    repoRoot = Directory.current;
  });

  setUp(() {
    // Use a distinct subdir per test under lib/ so the script's startsWith
    // check fires correctly. We avoid touching real feature directories.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    stagingRel = 'lib/.test_perf_facade_$stamp';
    stagingDir = Directory(p.join(repoRoot.path, stagingRel))
      ..createSync(recursive: true);
  });

  tearDown(() {
    if (stagingDir.existsSync()) stagingDir.deleteSync(recursive: true);
  });

  Future<({int exitCode, String stdout, String stderr})> runCheck(
    String relPath,
  ) async {
    final result = await Process.run(
      'dart',
      ['run', 'scripts/check_quality.dart', relPath],
      workingDirectory: repoRoot.path,
      runInShell: true,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  group('PERFORMANCE_FACADE — bans direct SDK imports outside the facade', () {
    test(
      'feature file with direct firebase_performance import is rejected',
      () async {
        // Stage a file that LOOKS like a feature consumer of the SDK.
        final relPath = '$stagingRel/listings_perf.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:firebase_performance/firebase_performance.dart';

class ListingsPerf {
  final tracer = FirebasePerformance.instance;
}
''');
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(combined, contains('PERFORMANCE_FACADE'));
        expect(combined, contains('firebase_performance'));
        expect(combined, contains(relPath));
        expect(r.exitCode, isNot(0));
      },
    );

    test(
      'sentry_flutter import that uses tracer surface is rejected',
      () async {
        final relPath = '$stagingRel/search_tracer.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:sentry_flutter/sentry_flutter.dart';

class SearchTracer {
  void start() {
    Sentry.startTransaction('search', 'op');
  }
}
''');
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(combined, contains('PERFORMANCE_FACADE'));
        expect(combined, contains('sentry_flutter'));
        expect(r.exitCode, isNot(0));
      },
    );

    test(
      'double-quoted firebase_performance import is also rejected (PR #239 H-1)',
      () async {
        // Gemini PR #239 review: the previous single-quote-only check
        // silently allowed `import "package:firebase_performance/...";`
        // imports to bypass the guard. This test pins the fix.
        final relPath = '$stagingRel/double_quoted_import.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import "package:firebase_performance/firebase_performance.dart";

class DoubleQuoted {
  final tracer = FirebasePerformance.instance;
}
''');
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(combined, contains('PERFORMANCE_FACADE'));
        expect(combined, contains('firebase_performance'));
        expect(r.exitCode, isNot(0));
      },
    );

    test(
      'sentry tracer usage far below the import is still detected (PR #239 H-1)',
      () async {
        // Gemini PR #239 review: the previous 50-line look-ahead window
        // missed tracer usage that occurred deeper in larger files. The
        // fix scans the whole file content. Pad the file with 100 filler
        // lines between the import and the tracer call to verify.
        final filler = List<String>.filled(100, '// filler line').join('\n');
        final relPath = '$stagingRel/far_below_tracer.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:sentry_flutter/sentry_flutter.dart';

$filler

class DeepTracer {
  void start() {
    Sentry.startTransaction('search', 'op');
  }
}
''');
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(
          combined,
          contains('PERFORMANCE_FACADE'),
          reason:
              'tracer usage 100 lines below the import must still be '
              'detected after the whole-file content scan landed',
        );
        expect(r.exitCode, isNot(0));
      },
    );

    test(
      'sentry_flutter import without tracer usage (error reporting only) is allowed',
      () async {
        final relPath = '$stagingRel/error_only.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorReporter {
  void report(Object e, StackTrace s) {
    Sentry.captureException(e, stackTrace: s);
  }
}
''');
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(combined, isNot(contains('PERFORMANCE_FACADE')));
      },
    );
  });

  group('PERFORMANCE_FACADE — allowlist', () {
    test(
      'lib/core/services/performance/firebase_performance_tracer.dart is allowed',
      () async {
        // Use the real facade file — it imports firebase_performance and
        // must not be flagged.
        const relPath =
            'lib/core/services/performance/firebase_performance_tracer.dart';
        final r = await runCheck(relPath);
        final combined = '${r.stdout}\n${r.stderr}';
        expect(combined, isNot(contains('PERFORMANCE_FACADE')));
      },
    );
  });
}
