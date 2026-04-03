import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  // Suppress overflow errors caused by grid layout in test viewports.
  final origOnError = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origOnError);

  group('PhotoGrid', () {
    testWidgets('renders correct number of tiles for given images', (
      tester,
    ) async {
      final images = ['/img/a.jpg', '/img/b.jpg', '/img/c.jpg'];

      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: images,
            onRemove: (_) {},
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
            imageFiles: const ['/img/a.jpg'],
            onRemove: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('onRemove callback fires when remove button is tapped', (
      tester,
    ) async {
      int? removedIndex;

      await pumpTestWidget(
        tester,
        SizedBox(
          height: 400,
          child: PhotoGrid(
            imageFiles: const ['/img/a.jpg', '/img/b.jpg'],
            onRemove: (i) => removedIndex = i,
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

      expect(removedIndex, equals(0));
    });

    testWidgets('popup menu shows reorder actions for middle item', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        SizedBox(
          height: 600,
          child: PhotoGrid(
            imageFiles: const ['/img/a.jpg', '/img/b.jpg', '/img/c.jpg'],
            onRemove: (_) {},
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
            imageFiles: const ['/img/a.jpg', '/img/b.jpg', '/img/c.jpg'],
            onRemove: (_) {},
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
            imageFiles: const ['/img/a.jpg'],
            onRemove: (_) {},
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
            imageFiles: const ['/img/a.jpg'],
            onRemove: (_) {},
            onReorder: (_, _) {},
          ),
        ),
      );

      expect(find.byType(DragTarget<int>), findsOneWidget);
    });
  });
}
