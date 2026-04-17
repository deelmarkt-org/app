import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Golden comparator that tolerates minor per-pixel colour differences.
///
/// Needed because macOS and Linux differ in font-hinting and sub-pixel
/// rendering, producing pixel-level RGB deltas on text-heavy goldens.
/// A tolerance of [maxDeltaRatio] (default 1%) suppresses platform noise
/// while still catching real regressions (layout shifts, wrong colours, etc.).
///
/// Register in [flutter_test_config.dart] or per-test:
/// ```dart
/// goldenFileComparator = TolerantGoldenComparator(Uri.file('test/path/'));
/// ```
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.maxDeltaRatio = 0.01});

  /// Maximum fraction of pixels that may differ (0.01 = 1%).
  final double maxDeltaRatio;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed) return true;

    if (result.diffPercent <= maxDeltaRatio) return true;

    final percentage = (result.diffPercent * 100).toStringAsFixed(2);
    fail(
      'Golden "$golden" differs by $percentage% '
      '(limit ${(maxDeltaRatio * 100).toStringAsFixed(0)}%). '
      'Run `flutter test --update-goldens` to regenerate.',
    );
  }
}

/// Registers [TolerantGoldenComparator] for the given test file URI.
///
/// Call once per test file (or globally in flutter_test_config.dart).
void useTolerantGoldenComparator({double maxDeltaRatio = 0.01}) {
  final Uri testUri = (goldenFileComparator as LocalFileComparator).basedir;
  goldenFileComparator = TolerantGoldenComparator(
    testUri.resolve('dummy_test.dart'),
    maxDeltaRatio: maxDeltaRatio,
  );
}

/// Pixel-level RGB Euclidean distance helper (unused in comparator but
/// available for diagnostic assertions in tests).
double pixelDistance(Color a, Color b) {
  final ar = (a.r * 255).round();
  final ag = (a.g * 255).round();
  final ab = (a.b * 255).round();
  final br = (b.r * 255).round();
  final bg = (b.g * 255).round();
  final bb = (b.b * 255).round();
  final dr = (ar - br).toDouble();
  final dg = (ag - bg).toDouble();
  final db = (ab - bb).toDouble();
  return math.sqrt(dr * dr + dg * dg + db * db) / (255 * math.sqrt(3));
}
