// Tests for the `_checkReviewInformation` step in scripts/check_aso.dart.
//
// PR for GH #162 promoted REVIEW_INFO_TODO from a warning to an error so any
// future TODO marker in fastlane/metadata/review_information/* breaks CI
// before a TestFlight submission can be cut. These tests pin that contract.
//
// Strategy: spawn the real `dart run scripts/check_aso.dart` against a
// temp directory injected via the ASO_REVIEW_INFO_DIR env var. We do NOT
// stub the iOS / Android locale checks — those run against the real repo
// and must already be green (validated by the existing aso-validate.yml CI).
// We assert ONLY on REVIEW_INFO_* error/exit-code behaviour because the
// other failure modes are covered by the live ASO copy.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory repoRoot;
  late Directory tmpDir;

  setUpAll(() {
    // Tests are launched from the repo root by `flutter test`, so the CWD
    // is already correct. We capture it once for the spawned subprocess.
    repoRoot = Directory.current;
  });

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('aso_review_info_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  /// Writes a complete review_information set into [tmpDir]. Callers can then
  /// overwrite individual files with TODO markers / empty content to assert
  /// each failure mode.
  void writeCleanFixture() {
    File(p.join(tmpDir.path, 'privacy_details.yaml')).writeAsStringSync('''
review_information:
  first_name: "Mahmut"
  last_name: "Kaya"
  phone_number: "+31686433636"
  email_address: "support@deelmarkt.com"
  demo_user: ""
  demo_password: ""
  notes: >
    DeelMarkt demo account for App Store reviewers.
''');
    File(p.join(tmpDir.path, 'first_name.txt')).writeAsStringSync('Mahmut\n');
    File(p.join(tmpDir.path, 'last_name.txt')).writeAsStringSync('Kaya\n');
    File(
      p.join(tmpDir.path, 'phone_number.txt'),
    ).writeAsStringSync('+31686433636\n');
    File(
      p.join(tmpDir.path, 'email_address.txt'),
    ).writeAsStringSync('support@deelmarkt.com\n');
    File(
      p.join(tmpDir.path, 'notes.txt'),
    ).writeAsStringSync('DeelMarkt demo account.\n');
  }

  /// Spawns the real script with ASO_REVIEW_INFO_DIR pointed at [tmpDir].
  /// Returns (exitCode, combined stdout+stderr).
  Future<({int exitCode, String stderr, String stdout})> runScript() async {
    // runInShell is required on Windows so the shell resolves `dart.bat`;
    // it is harmless on macOS/Linux.
    final result = await Process.run(
      'dart',
      ['run', 'scripts/check_aso.dart'],
      workingDirectory: repoRoot.path,
      environment: {'ASO_REVIEW_INFO_DIR': tmpDir.path},
      runInShell: true,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  group('_checkReviewInformation — clean fixture', () {
    test(
      'clean YAML + clean .txt files do not surface REVIEW_INFO_*',
      () async {
        writeCleanFixture();
        final r = await runScript();
        // Exit code may be 0 or 1 depending on the live ASO copy state — we
        // assert only that no REVIEW_INFO_* line was emitted.
        expect(r.stderr, isNot(contains('REVIEW_INFO_TODO')));
        expect(r.stderr, isNot(contains('REVIEW_INFO_EMPTY')));
      },
    );
  });

  group('_checkReviewInformation — TODO regression', () {
    test('double-quoted [TODO] in YAML is reported as error', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      yaml.writeAsStringSync(
        yaml.readAsStringSync().replaceAll('"Mahmut"', '"[TODO fill name]"'),
      );
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.stderr, contains('[TODO fill name]'));
      expect(
        r.exitCode,
        isNot(0),
        reason: 'TODO marker MUST fail CI (was warning before #162 close-out)',
      );
    });

    test('single-quoted [TODO] in YAML is reported as error', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      yaml.writeAsStringSync(
        yaml.readAsStringSync().replaceAll('"Kaya"', "'[TODO surname]'"),
      );
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.exitCode, isNot(0));
    });

    test('comment line mentioning [TODO] does NOT trigger', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      yaml.writeAsStringSync(
        '# Reviewer note: never commit values like [TODO] here.\n${yaml.readAsStringSync()}',
      );
      final r = await runScript();
      expect(r.stderr, isNot(contains('REVIEW_INFO_TODO')));
    });

    test('TODO marker in per-field .txt mirror is reported', () async {
      writeCleanFixture();
      File(
        p.join(tmpDir.path, 'first_name.txt'),
      ).writeAsStringSync('[TODO real first name]\n');
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.stderr, contains('first_name.txt'));
      expect(r.exitCode, isNot(0));
    });

    // GH #162 PR #218 review (Gemini medium) — original regex only matched
    // `[TODO` immediately after a colon or as the first character inside
    // quotes. Embedded markers and block-scalar lines slipped through.
    test(
      'TODO embedded mid-string in double-quoted YAML is reported',
      () async {
        writeCleanFixture();
        final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
        yaml.writeAsStringSync(
          yaml.readAsStringSync().replaceAll(
            '"Mahmut"',
            '"Mahmut [TODO confirm spelling]"',
          ),
        );
        final r = await runScript();
        expect(r.stderr, contains('REVIEW_INFO_TODO'));
        expect(r.exitCode, isNot(0));
      },
    );

    test('TODO inside folded block scalar (notes: >) is reported', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      // Replace the single-line notes value with a folded block scalar that
      // hides the TODO marker on a continuation line.
      yaml.writeAsStringSync(
        yaml.readAsStringSync().replaceAll(
          '  notes: >\n    DeelMarkt demo account for App Store reviewers.',
          '  notes: >\n    DeelMarkt demo account.\n    [TODO write proper reviewer instructions]',
        ),
      );
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.exitCode, isNot(0));
    });

    test('TODO inside literal block scalar (notes: |) is reported', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      yaml.writeAsStringSync(
        yaml.readAsStringSync().replaceAll(
          '  notes: >\n    DeelMarkt demo account for App Store reviewers.',
          '  notes: |\n    Line one\n    [TODO complete second line]',
        ),
      );
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.exitCode, isNot(0));
    });

    // GH #225 — YAML inline comments (`value  # comment`) were not stripped
    // before scanning, so a `# TODO` after a real value slipped through. The
    // fix strips space-prefixed `#…EOL` per YAML 1.2 §6.6.
    test('inline `# TODO` comment after a value trips the gate', () async {
      writeCleanFixture();
      final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
      yaml.writeAsStringSync(
        yaml.readAsStringSync().replaceAll(
          '"Mahmut"',
          '"Mahmut"  # TODO confirm spelling',
        ),
      );
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_TODO'));
      expect(r.stderr, contains('TODO confirm spelling'));
      expect(r.exitCode, isNot(0));
    });

    test(
      'value containing `#` with no leading whitespace is NOT treated as comment',
      () async {
        // `notes: "use #1 keyword"` — the `#` is part of the quoted scalar,
        // not a YAML comment. The strip must leave the value intact so legit
        // hashtags do not break the gate. We assert that this benign value
        // does not trip the TODO check.
        writeCleanFixture();
        final yaml = File(p.join(tmpDir.path, 'privacy_details.yaml'));
        yaml.writeAsStringSync(
          yaml.readAsStringSync().replaceAll(
            '  notes: >\n    DeelMarkt demo account for App Store reviewers.',
            '  notes: "use #1 priority for reviewers"',
          ),
        );
        final r = await runScript();
        expect(r.stderr, isNot(contains('REVIEW_INFO_TODO')));
      },
    );
  });

  group('_checkReviewInformation — empty .txt mirror', () {
    test('empty notes.txt is reported as REVIEW_INFO_EMPTY', () async {
      writeCleanFixture();
      File(p.join(tmpDir.path, 'notes.txt')).writeAsStringSync('   \n');
      final r = await runScript();
      expect(r.stderr, contains('REVIEW_INFO_EMPTY'));
      expect(r.stderr, contains('notes.txt'));
      expect(r.exitCode, isNot(0));
    });
  });
}
