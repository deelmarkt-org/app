/// Golden tests for [PhotoGridTile] — captures the 4 upload-state variants
/// in both light and dark themes.
///
/// Run normally to compare against committed goldens.
/// Run with `--update-goldens` to regenerate when the widget changes.
///
/// Golden PNG files are committed alongside this test so CI catches
/// pixel regressions without requiring a real device.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

import '../../../../../helpers/tolerant_golden_comparator.dart';

const _uploadedImage = SellImage(
  id: 'uploaded-1',
  localPath: '/test/image.jpg',
  status: ImageUploadStatus.uploaded,
);

const _pendingImage = SellImage(
  id: 'pending-1',
  localPath: '/test/image.jpg',
  status: ImageUploadStatus.uploading,
);

const _failedRetryImage = SellImage(
  id: 'failed-retry-1',
  localPath: '/test/image.jpg',
  status: ImageUploadStatus.failed,
);

const _failedTerminalImage = SellImage(
  id: 'failed-terminal-1',
  localPath: '/test/image.jpg',
  status: ImageUploadStatus.failed,
  isRetryable: false,
);

Widget _buildTile(SellImage image, ThemeData theme, {VoidCallback? onRetry}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SizedBox(
        width: 120,
        height: 120,
        child: PhotoGridTile(image: image, index: 0, onRetry: onRetry),
      ),
    ),
  );
}

void main() {
  // Use a tolerant comparator so sub-pixel font-rendering differences between
  // Linux CI (Freetype) and developer machines (macOS CoreText / Windows
  // DirectWrite) do not cause false failures. 0.5% tolerance is well above
  // the observed 0.01% diff on the failed_terminal variants and well below
  // any real regression (which would produce ≥1% diff).
  setUpAll(() {
    goldenFileComparator = TolerantGoldenFileComparator.forTestFile(
      'test/features/sell/presentation/widgets/photo_step/'
      'photo_grid_tile_golden_test.dart',
    );
  });

  // Suppress image decode errors for fake file paths used in golden tests.
  final origHandler = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          final s = details.exceptionAsString();
          if (s.contains('Image') || s.contains('overflowed')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origHandler);

  group('PhotoGridTile goldens', () {
    for (final (label, theme) in [
      ('light', DeelmarktTheme.light),
      ('dark', DeelmarktTheme.dark),
    ]) {
      group(label, () {
        testWidgets('uploaded — $label', (tester) async {
          await tester.pumpWidget(_buildTile(_uploadedImage, theme));
          await tester.pump();
          await expectLater(
            find.byType(PhotoGridTile),
            matchesGoldenFile('goldens/photo_grid_tile_uploaded_$label.png'),
          );
        });

        testWidgets('uploading (pending overlay) — $label', (tester) async {
          await tester.pumpWidget(_buildTile(_pendingImage, theme));
          await tester.pump();
          await expectLater(
            find.byType(PhotoGridTile),
            matchesGoldenFile('goldens/photo_grid_tile_uploading_$label.png'),
          );
        });

        testWidgets('failed-retryable — $label', (tester) async {
          await tester.pumpWidget(
            _buildTile(_failedRetryImage, theme, onRetry: () {}),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(PhotoGridTile),
            matchesGoldenFile(
              'goldens/photo_grid_tile_failed_retry_$label.png',
            ),
          );
        });

        testWidgets('failed-terminal — $label', (tester) async {
          await tester.pumpWidget(_buildTile(_failedTerminalImage, theme));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(PhotoGridTile),
            matchesGoldenFile(
              'goldens/photo_grid_tile_failed_terminal_$label.png',
            ),
          );
        });
      });
    }
  });
}
