import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// A [GoldenFileComparator] that tolerates a small percentage of mismatched
/// pixels between the golden baseline and the rendered image.
///
/// CI runners (Linux/Freetype) and developer machines (macOS/CoreText or
/// Windows/DirectWrite) apply slightly different sub-pixel font hinting.
/// This causes pixel-level differences in golden screenshots that are
/// visually imperceptible but cause strict [LocalFileComparator] to fail.
///
/// Use this comparator in golden test files that need to pass on both
/// platforms:
///
/// ```dart
/// setUpAll(() {
///   goldenFileComparator = TolerantGoldenFileComparator.forTestFile(
///     'test/path/to/my_golden_test.dart',
///     maxDiffPercentage: 0.5,
///   );
/// });
/// ```
///
/// The [maxDiffPercentage] defaults to [defaultMaxDiffPercentage] (0.5%).
/// Increase only if sub-pixel differences are larger; keep as small as
/// possible to catch real regressions.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(
    super.testFile, {
    this.maxDiffPercentage = defaultMaxDiffPercentage,
  });

  /// Default tolerance: 0.5% of total pixels.
  static const double defaultMaxDiffPercentage = 0.5;

  /// Maximum percentage of differing pixels before the comparison fails.
  final double maxDiffPercentage;

  /// Convenience factory that resolves [relativeTestFilePath] against
  /// the current working directory (i.e. the project root when running
  /// `flutter test`).
  factory TolerantGoldenFileComparator.forTestFile(
    String relativeTestFilePath, {
    double maxDiffPercentage = defaultMaxDiffPercentage,
  }) {
    return TolerantGoldenFileComparator(
      Uri.base.resolve(relativeTestFilePath),
      maxDiffPercentage: maxDiffPercentage,
    );
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed) return true;

    final double diffPercent = result.diffPercent * 100;
    if (diffPercent <= maxDiffPercentage) {
      // ignore: avoid_print
      print(
        'TolerantGoldenFileComparator: $golden — '
        '${diffPercent.toStringAsFixed(4)}% diff '
        '(≤ $maxDiffPercentage% tolerance) → PASS',
      );
      return true;
    }

    return false;
  }
}
