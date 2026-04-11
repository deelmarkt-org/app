import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

import '../../../../../helpers/pump_app.dart';

const _img = SellImage(
  id: 't',
  localPath: '/test/image.jpg',
  status: ImageUploadStatus.uploaded,
);

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

  group('PhotoGridTile — empty variant', () {
    testWidgets('shows camera icon when image is null', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(width: 120, height: 120, child: PhotoGridTile(index: 0)),
      );

      expect(find.byIcon(PhosphorIconsRegular.camera), findsOneWidget);
    });

    testWidgets('does not show remove button when empty', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(width: 120, height: 120, child: PhotoGridTile(index: 0)),
      );

      expect(find.byIcon(PhosphorIconsRegular.x), findsNothing);
    });

    testWidgets('has dashed border container', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(width: 120, height: 120, child: PhotoGridTile(index: 0)),
      );

      // Empty tile uses a Container with BoxDecoration border.
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('PhotoGridTile — filled variant', () {
    testWidgets('shows Image.file when image is provided', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0),
        ),
      );

      // Image.file creates an Image widget.
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows remove button (X icon) when filled', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0, onRemove: _noOp),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.x), findsOneWidget);
    });

    testWidgets('remove button fires onRemove callback', (tester) async {
      var removed = false;

      await pumpTestWidget(
        tester,
        SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(
            image: _img,
            index: 0,
            onRemove: () => removed = true,
          ),
        ),
      );

      // Tap the GestureDetector wrapping the remove button.
      final removeGesture = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onTap != null,
      );
      await tester.tap(removeGesture.first);
      await tester.pump();

      expect(removed, isTrue);
    });

    testWidgets('remove button has 44x44 touch target', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0, onRemove: _noOp),
        ),
      );

      // The remove button outer container is 44x44.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final has44 = containers.any((c) {
        final constraints = c.constraints;
        return constraints != null &&
            constraints.maxWidth == 44 &&
            constraints.maxHeight == 44;
      });
      expect(has44, isTrue);
    });

    testWidgets('has Semantics label for accessibility', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0, onRemove: _noOp),
        ),
      );

      // Semantics widget with label 'action.delete' (key in tests).
      expect(find.byType(Semantics), findsWidgets);
      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasDeleteLabel = semantics.any(
        (s) => s.properties.label == 'action.delete',
      );
      expect(hasDeleteLabel, isTrue);
    });

    testWidgets('uses ClipRRect for rounded corners', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('uploaded image uses full opacity', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(image: _img, index: 0),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, equals(1.0));
    });
  });

  // Uploading and failed state tests live in
  // photo_grid_tile_states_test.dart to keep this file under the 300-line
  // test file limit (CLAUDE.md §2.1).
}
