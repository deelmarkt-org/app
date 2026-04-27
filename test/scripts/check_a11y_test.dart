// Tests for `scripts/check_a11y.dart` — closes P-54 D16/C2.
//
// Strategy: same as `test/scripts/check_quality_performance_facade_test.dart`
// — spawn the real `dart run scripts/check_a11y.dart <file>` against
// staged Dart fixtures placed under `lib/.test_a11y_<stamp>/` so the
// script's `lib/` predicate fires. Each test cleans up after itself.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory repoRoot;
  late String stagingRel;

  setUpAll(() {
    repoRoot = Directory.current;
  });

  setUp(() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    // Use `presentation` subdir so `_isPresentationFile` matches and
    // a11y checks fire (a11y rules apply to presentation only).
    stagingRel = 'lib/features/.test_a11y_$stamp/presentation';
    Directory(p.join(repoRoot.path, stagingRel)).createSync(recursive: true);
  });

  tearDown(() {
    final parent = Directory(p.join(repoRoot.path, p.dirname(stagingRel)));
    if (parent.existsSync()) parent.deleteSync(recursive: true);
  });

  Future<({int exitCode, String stdout, String stderr})> runCheck(
    String relPath,
  ) async {
    final result = await Process.run(
      'dart',
      ['run', 'scripts/check_a11y.dart', relPath],
      workingDirectory: repoRoot.path,
      runInShell: true,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  group('TOUCH_TARGET — flags <44 px on tappable surfaces', () {
    test('GestureDetector with height: 32 is rejected', () async {
      final relPath = '$stagingRel/small_tap.dart';
      File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class Small extends StatelessWidget {
  const Small({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        height: 32,
        width: 100,
        child: const Placeholder(),
      ),
    );
  }
}
''');
      final r = await runCheck(relPath);
      final combined = '${r.stdout}\n${r.stderr}';
      expect(combined, contains('TOUCH_TARGET'));
      expect(combined, contains('height: 32'));
      expect(r.exitCode, isNot(0));
    });

    test('IconButton with width: 24 height: 24 is rejected', () async {
      final relPath = '$stagingRel/tiny_icon_button.dart';
      File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class TinyIcon extends StatelessWidget {
  const TinyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      iconSize: 16,
      onPressed: () {},
      constraints: const BoxConstraints(width: 24, height: 24),
    );
  }
}
''');
      final r = await runCheck(relPath);
      final combined = r.stdout + r.stderr;
      expect(combined, contains('TOUCH_TARGET'));
      expect(r.exitCode, isNot(0));
    });

    test(
      'non-tappable SizedBox with width: 8 is allowed (not a tap target)',
      () async {
        final relPath = '$stagingRel/spacer.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class Spacer extends StatelessWidget {
  const Spacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 8, height: 8);
  }
}
''');
        final r = await runCheck(relPath);
        final combined = r.stdout + r.stderr;
        expect(combined, isNot(contains('TOUCH_TARGET')));
      },
    );

    test(
      'inline width:100, height:20 catches the SUB-44 height (PR #241 H-1)',
      () async {
        // Gemini PR #241 review: `firstMatch` short-circuited on the
        // first dimension (width: 100 → passes ≥44), missing the
        // sub-44 height. `allMatches` audits both. This regression
        // test pins the fix.
        final relPath = '$stagingRel/inline_dims.dart';
        File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class InlineDims extends StatelessWidget {
  const InlineDims({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: const SizedBox(width: 100, height: 20),
    );
  }
}
''');
        final r = await runCheck(relPath);
        final combined = r.stdout + r.stderr;
        expect(combined, contains('TOUCH_TARGET'));
        expect(
          combined,
          contains('height: 20'),
          reason:
              'allMatches must catch the second dimension on the same '
              'line — height:20 is sub-44 even though width:100 is fine.',
        );
        expect(r.exitCode, isNot(0));
      },
    );

    test('44×44 boundary is allowed (>= threshold)', () async {
      final relPath = '$stagingRel/exact_size.dart';
      File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class Exact extends StatelessWidget {
  const Exact({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: const SizedBox(width: 44, height: 44),
    );
  }
}
''');
      final r = await runCheck(relPath);
      final combined = r.stdout + r.stderr;
      expect(combined, isNot(contains('TOUCH_TARGET')));
    });
  });

  group('RAW_COLOR — flags Color(0xFF...) outside design-system', () {
    test('feature file with raw Color(0xFFRRGGBB) is rejected', () async {
      final relPath = '$stagingRel/hardcoded_color.dart';
      File(p.join(repoRoot.path, relPath)).writeAsStringSync('''
import 'package:flutter/material.dart';

class Hardcoded extends StatelessWidget {
  const Hardcoded({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFCC0000));
  }
}
''');
      final r = await runCheck(relPath);
      final combined = r.stdout + r.stderr;
      expect(combined, contains('RAW_COLOR'));
      expect(r.exitCode, isNot(0));
    });

    test('design-system token file is allowed to define raw colors', () async {
      // Use the real tokens path — the script's allowlist must accept it.
      const relPath = 'lib/core/design_system/colors.dart';
      final r = await runCheck(relPath);
      final combined = r.stdout + r.stderr;
      expect(combined, isNot(contains('RAW_COLOR')));
    });
  });
}
