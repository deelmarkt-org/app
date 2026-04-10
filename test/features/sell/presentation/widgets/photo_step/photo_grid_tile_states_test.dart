import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

import '../../../../../helpers/pump_app.dart';

void _noOp() {}

void main() {
  // Suppress image decode errors from fake file paths.
  final origOnError = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          final s = details.exceptionAsString();
          if (s.contains('Image') || s.contains('overflowed')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origOnError);

  group('PhotoGridTile — uploading state', () {
    const uploadingImage = SellImage(
      id: 'u',
      localPath: '/test/image.jpg',
      status: ImageUploadStatus.uploading,
    );

    // CircularProgressIndicator animates infinitely, so we can't use
    // pumpAndSettle. Use pumpTestWidgetAnimated + pump() instead.

    testWidgets('shows CircularProgressIndicator overlay', (tester) async {
      await pumpTestWidgetAnimated(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: uploadingImage, index: 0),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dims the image (opacity < 1)', (tester) async {
      await pumpTestWidgetAnimated(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: uploadingImage, index: 0),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('has uploadingImage Semantics label', (tester) async {
      await pumpTestWidgetAnimated(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: uploadingImage, index: 0),
        ),
      );

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasLabel = semantics.any(
        (s) => s.properties.label == 'sell.uploadingImage',
      );
      expect(hasLabel, isTrue);
    });

    testWidgets('pending state shows spinner (same as uploading)', (
      tester,
    ) async {
      const pendingImage = SellImage(id: 'p', localPath: '/test/image.jpg');

      await pumpTestWidgetAnimated(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: pendingImage, index: 0),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PhotoGridTile — failed state', () {
    const retryableFailedImage = SellImage(
      id: 'f',
      localPath: '/test/image.jpg',
      status: ImageUploadStatus.failed,
      errorKey: 'sell.uploadErrorNetwork',
    );

    const terminalFailedImage = SellImage(
      id: 'f',
      localPath: '/test/image.jpg',
      status: ImageUploadStatus.failed,
      errorKey: 'sell.uploadErrorTooLarge',
      isRetryable: false,
    );

    testWidgets('retryable failure shows retry IconButton', (tester) async {
      var retried = false;

      await pumpTestWidget(
        tester,
        SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(
            image: retryableFailedImage,
            index: 0,
            onRetry: () => retried = true,
          ),
        ),
      );

      final iconButton = find.byIcon(PhosphorIconsRegular.arrowClockwise);
      expect(iconButton, findsOneWidget);

      await tester.tap(iconButton);
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('retryable failure has retryUpload Semantics label', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(
            image: retryableFailedImage,
            index: 0,
            onRetry: _noOp,
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasLabel = semantics.any(
        (s) => s.properties.label == 'sell.retryUpload',
      );
      expect(hasLabel, isTrue);
    });

    testWidgets('terminal failure shows warning icon (no retry)', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: terminalFailedImage, index: 0),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.warning), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.arrowClockwise), findsNothing);
    });

    testWidgets(
      'retryable failure with null onRetry still shows warning icon',
      (tester) async {
        await pumpTestWidget(
          tester,
          const SizedBox(
            width: 120,
            height: 120,
            child: PhotoGridTile(image: retryableFailedImage, index: 0),
          ),
        );

        // canRetry is true but onRetry is null → should fall back to warning.
        expect(find.byIcon(PhosphorIconsRegular.warning), findsOneWidget);
      },
    );

    testWidgets('failed state still dims the image', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: terminalFailedImage, index: 0),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, lessThan(1.0));
    });
  });
}
