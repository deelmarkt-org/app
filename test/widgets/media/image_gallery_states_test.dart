import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/media/image_gallery.dart';
import 'package:deelmarkt/widgets/media/image_gallery_fullscreen.dart';

import 'image_gallery_test_helper.dart';

void main() {
  group('ImageGallery states', () {
    testWidgets('swipe changes page and fires onPageChanged', (tester) async {
      int? lastPage;
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            onPageChanged: (i) => lastPage = i,
          ),
        ),
      );
      // Use fling with velocity — works reliably inside the outer
      // GestureDetector because drag gestures pass through to the
      // PageView's scroll recognizer once momentum is applied.
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 2000);
      await tester.pumpAndSettle();
      expect(lastPage, 1);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('initialPage is respected', (tester) async {
      int? lastPage;
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            initialPage: 2,
            onPageChanged: (i) => lastPage = i,
          ),
        ),
      );
      // Scroll offset should reflect page 2 on initial build
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 2);
      // lastPage not invoked on initial build — only on change
      expect(lastPage, isNull);
    });

    testWidgets('initialPage > length is clamped to last index', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGallery(
            imageUrls: sampleImageUrls,
            initialPage: 100,
          ),
        ),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      // sampleImageUrls has 3 items → last index is 2
      expect(pageView.controller?.initialPage, 2);
    });

    testWidgets('initialPage < 0 is clamped to 0', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGallery(
            imageUrls: sampleImageUrls,
            initialPage: -5,
          ),
        ),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 0);
    });

    testWidgets('empty string URLs filtered out before rendering', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(child: const ImageGallery(imageUrls: ['', '', ''])),
      );
      // All empty → treated as empty list → placeholder shown
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('external PageController is used (not replaced)', (
      tester,
    ) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            controller: controller,
          ),
        ),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(identical(pageView.controller, controller), isTrue);
      controller.dispose();
    });

    testWidgets('single image: no swipe between pages', (tester) async {
      int pageChanges = 0;
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: const ['https://example.com/only.jpg'],
            onPageChanged: (_) => pageChanges++,
          ),
        ),
      );
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(pageChanges, 0);
    });

    testWidgets('tap with null onTap pushes fullscreen route', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(child: const ImageGallery(imageUrls: sampleImageUrls)),
      );
      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();
      // Verify the fullscreen widget was actually mounted by the default
      // tap handler — meaningful assertion, not just exception absence.
      expect(find.byType(ImageGalleryFullscreen), findsOneWidget);
    });

    testWidgets('external controller is NOT disposed when widget unmounts', (
      tester,
    ) async {
      final controller = PageController();
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            controller: controller,
          ),
        ),
      );
      // Unmount the widget — the parent-supplied controller must survive.
      await tester.pumpWidget(const SizedBox.shrink());
      // If the controller were disposed, accessing hasClients would throw.
      expect(() => controller.hasClients, returnsNormally);
      controller.dispose();
    });
  });
}
