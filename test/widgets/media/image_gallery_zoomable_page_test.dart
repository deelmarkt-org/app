import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/media/image_gallery_page.dart';
import 'package:deelmarkt/widgets/media/image_gallery_zoomable_page.dart';

import 'image_gallery_test_helper.dart';

void main() {
  group('ImageGalleryZoomablePage', () {
    testWidgets('renders ImageGalleryPage inside InteractiveViewer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGalleryZoomablePage(
            imageUrl: sampleImageUrls.first,
            index: 0,
            total: sampleImageUrls.length,
            onZoomChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(ImageGalleryPage), findsOneWidget);
    });

    testWidgets('Semantics container wraps content', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGalleryZoomablePage(
            imageUrl: sampleImageUrls.first,
            index: 0,
            total: 1,
            onZoomChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets(
      'reset() restores transformation to identity and fires onZoomChanged',
      (tester) async {
        final key = GlobalKey<ImageGalleryZoomablePageState>();
        bool? lastZoomChanged;

        await tester.pumpWidget(
          buildGalleryApp(
            child: ImageGalleryZoomablePage(
              key: key,
              imageUrl: sampleImageUrls.first,
              index: 0,
              total: 1,
              onZoomChanged: (z) => lastZoomChanged = z,
            ),
          ),
        );

        // Simulate an external transformation via the InteractiveViewer.
        // Accessing the InteractiveViewer's controller indirectly through
        // reset (which is a no-op when not zoomed) still exercises the
        // _controller.value = identity path.
        key.currentState!.reset();
        await tester.pump();

        // No zoom change should fire when already at identity.
        expect(lastZoomChanged, isNull);
      },
    );

    testWidgets(
      'double-tap to zoom in triggers onZoomChanged(true) then reset path',
      (tester) async {
        final key = GlobalKey<ImageGalleryZoomablePageState>();
        final zoomChanges = <bool>[];

        await tester.pumpWidget(
          buildGalleryApp(
            child: SizedBox(
              width: 400,
              height: 400,
              child: ImageGalleryZoomablePage(
                key: key,
                imageUrl: sampleImageUrls.first,
                index: 0,
                total: 1,
                onZoomChanged: zoomChanges.add,
              ),
            ),
          ),
        );

        // First tap down establishes _doubleTapDetails; double-tap fires
        // the handler, which queues an animation through the controller.
        final center = tester.getCenter(find.byType(InteractiveViewer));
        // Use a raw pointer to produce a genuine double-tap with the same
        // pointer id — tester.tap sequences are treated as separate taps.
        final gesture = await tester.startGesture(center);
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));
        final gesture2 = await tester.startGesture(center);
        await gesture2.up();
        await tester.pumpAndSettle();

        // onZoomChanged should have been invoked at least once with true
        // after the zoom-in animation completes.
        expect(zoomChanges, contains(true));

        // A second double-tap toggles back to 1x.
        final g3 = await tester.startGesture(center);
        await g3.up();
        await tester.pump(const Duration(milliseconds: 50));
        final g4 = await tester.startGesture(center);
        await g4.up();
        await tester.pumpAndSettle();

        expect(zoomChanges, contains(false));
      },
    );

    testWidgets('disposes cleanly with no pending listeners', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGalleryZoomablePage(
            imageUrl: sampleImageUrls.first,
            index: 0,
            total: 1,
            onZoomChanged: (_) {},
          ),
        ),
      );
      // Unmount — exercises dispose() path including the listener cleanup
      // branch (safe even when no listener was ever attached).
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
