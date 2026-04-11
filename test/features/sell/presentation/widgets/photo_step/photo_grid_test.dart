// TODO(#133): File exceeds 300-line limit (364 lines). Split into focused test groups.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

import '../../../../../helpers/pump_app.dart';

SellImage _img(String id, String path) =>
    SellImage(id: id, localPath: path, status: ImageUploadStatus.uploaded);

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

  group('PhotoGrid', () {
    testWidgets('renders correct number of tiles for given images', (
      tester,
    ) async {
      final images = [
        _img('a', '/img/a.jpg'),
        _img('b', '/img/b.jpg'),
        _img('c', '/img/c.jpg'),
      ];

      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: images,
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(PhotoGridTile), findsNWidgets(3));
    });

    testWidgets('renders zero tiles when imageFiles is empty', (tester) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: const [],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(PhotoGridTile), findsNothing);
    });

    testWidgets('uses GridView.builder for rendering', (tester) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: [_img('a', '/img/a.jpg')],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('onRemove callback fires when remove button is tapped', (
      tester,
    ) async {
      String? removedId;

      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: [_img('a', '/img/a.jpg'), _img('b', '/img/b.jpg')],
            onRemove: (id) => removedId = id,
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      // The remove button uses PhosphorIconsRegular.x wrapped in
      // a GestureDetector — find the first one and tap it.
      final removeButtons = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onTap != null,
      );
      expect(removeButtons, findsWidgets);

      await tester.tap(removeButtons.first);
      await tester.pump();

      expect(removedId, equals('a'));
    });

    testWidgets('popup menu shows reorder actions for middle item', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [
              _img('a', '/img/a.jpg'),
              _img('b', '/img/b.jpg'),
              _img('c', '/img/c.jpg'),
            ],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      // Find popup menu buttons — each non-edge tile has one.
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      expect(popupMenuButtons, findsWidgets);

      // Tap the first popup menu button (for first tile, which has moveDown).
      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();

      // Should show menu items. The first tile only has moveDown.
      expect(find.text('sell.moveDown'), findsOneWidget);
    });

    testWidgets('onReorder callback fires via popup menu', (tester) async {
      int? fromIndex;
      int? toIndex;

      await pumpTestWidget(
        tester,
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [
              _img('a', '/img/a.jpg'),
              _img('b', '/img/b.jpg'),
              _img('c', '/img/c.jpg'),
            ],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (from, to) {
              fromIndex = from;
              toIndex = to;
            },
          ),
        ),
      );

      // Open first popup menu (tile at index 0).
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();

      // Tap "moveDown" action.
      await tester.tap(find.text('sell.moveDown'));
      await tester.pumpAndSettle();

      // moveDown for index 0: onReorder(0, 2).
      expect(fromIndex, equals(0));
      expect(toIndex, equals(2));
    });

    testWidgets('LongPressDraggable wraps each tile', (tester) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: [_img('a', '/img/a.jpg')],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(LongPressDraggable<int>), findsOneWidget);
    });

    testWidgets('DragTarget wraps each tile', (tester) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: [_img('a', '/img/a.jpg')],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(DragTarget<int>), findsOneWidget);
    });

    testWidgets('single tile has no reorder popup menu (first == last guard)', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: [_img('only', '/img/only.jpg')],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('middle tile popup menu shows all three reorder actions', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [
              _img('a', '/img/a.jpg'),
              _img('b', '/img/b.jpg'),
              _img('c', '/img/c.jpg'),
            ],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      // The middle tile (index 1) has moveToFront, moveUp, moveDown.
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
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [
              _img('a', '/img/a.jpg'),
              _img('b', '/img/b.jpg'),
              _img('c', '/img/c.jpg'),
            ],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (f, t) {
              from = f;
              to = t;
            },
          ),
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
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [
              _img('a', '/img/a.jpg'),
              _img('b', '/img/b.jpg'),
              _img('c', '/img/c.jpg'),
            ],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (f, t) {
              from = f;
              to = t;
            },
          ),
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
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: [_img('a', '/img/a.jpg'), _img('b', '/img/b.jpg')],
            onRemove: (_) {},
            onRetry: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      // Tap the last tile's popup menu.
      await tester.tap(find.byType(PopupMenuButton<String>).at(1));
      await tester.pumpAndSettle();

      expect(find.text('sell.moveDown'), findsNothing);
      expect(find.text('sell.moveUp'), findsOneWidget);
    });
  });
}
