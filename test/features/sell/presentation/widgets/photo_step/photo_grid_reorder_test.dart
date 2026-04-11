import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid.dart';

import '../../../../../helpers/pump_app.dart';

SellImage _img(String id, String path) =>
    SellImage(id: id, localPath: path, status: ImageUploadStatus.uploaded);

/// Builds a [PhotoGrid] with the given [imageFiles] inside a fixed-size box.
Widget _wrap(
  List<SellImage> imageFiles, {
  void Function(int, int)? onReorder,
  double height = 600,
}) => SizedBox(
  height: height,
  child: PhotoGrid(
    imageFiles: imageFiles,
    onRemove: (_) {},
    onRetry: (_) {},
    onReorder: onReorder ?? (_, _) {},
  ),
);

void main() {
  // Suppress overflow + image decode errors in test viewports.
  final origOnError = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          final s = details.exceptionAsString();
          if (s.contains('overflowed') || s.contains('Image')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origOnError);

  group('PhotoGrid — reorder popup menu', () {
    testWidgets('single tile has no reorder popup menu (first == last guard)', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        _wrap([_img('only', '/img/only.jpg')], height: 400),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('middle tile popup menu shows all three reorder actions', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        _wrap([
          _img('a', '/img/a.jpg'),
          _img('b', '/img/b.jpg'),
          _img('c', '/img/c.jpg'),
        ]),
      );

      // Each non-trivial tile gets one popup menu.
      final popups = find.byType(PopupMenuButton<String>);
      expect(popups, findsNWidgets(3));

      await tester.tap(popups.at(1));
      await tester.pumpAndSettle();

      expect(find.text('sell.moveToFront'), findsOneWidget);
      expect(find.text('sell.moveUp'), findsOneWidget);
      expect(find.text('sell.moveDown'), findsOneWidget);
    });

    testWidgets('moveToFront from middle tile fires onReorder(1, 0)', (
      tester,
    ) async {
      int? from;
      int? to;

      await pumpTestWidget(
        tester,
        _wrap(
          [
            _img('a', '/img/a.jpg'),
            _img('b', '/img/b.jpg'),
            _img('c', '/img/c.jpg'),
          ],
          onReorder: (f, t) {
            from = f;
            to = t;
          },
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('sell.moveToFront'));
      await tester.pumpAndSettle();

      expect(from, equals(1));
      expect(to, equals(0));
    });

    testWidgets('moveUp from middle tile fires onReorder(1, 0)', (
      tester,
    ) async {
      int? from;
      int? to;

      await pumpTestWidget(
        tester,
        _wrap(
          [
            _img('a', '/img/a.jpg'),
            _img('b', '/img/b.jpg'),
            _img('c', '/img/c.jpg'),
          ],
          onReorder: (f, t) {
            from = f;
            to = t;
          },
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('sell.moveUp'));
      await tester.pumpAndSettle();

      expect(from, equals(1));
      expect(to, equals(0));
    });

    testWidgets('last tile popup menu does not show moveDown', (tester) async {
      await pumpTestWidget(
        tester,
        _wrap([_img('a', '/img/a.jpg'), _img('b', '/img/b.jpg')]),
      );

      await tester.tap(find.byType(PopupMenuButton<String>).at(1));
      await tester.pumpAndSettle();

      expect(find.text('sell.moveDown'), findsNothing);
      expect(find.text('sell.moveUp'), findsOneWidget);
    });
  });
}
