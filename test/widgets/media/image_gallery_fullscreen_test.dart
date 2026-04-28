import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/widgets/buttons/circle_icon_button.dart';
import 'package:deelmarkt/widgets/media/image_gallery_fullscreen.dart';
import 'package:deelmarkt/widgets/media/image_gallery_page.dart';

import 'image_gallery_test_helper.dart';

void main() {
  group('ImageGalleryFullscreen', () {
    testWidgets('renders with initial index', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(
            imageUrls: sampleImageUrls,
            initialIndex: 1,
          ),
        ),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 1);
    });

    testWidgets('renders with initial index = 0', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 0);
    });

    testWidgets('displays photo counter when multiple images', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      expect(find.text('image_gallery.photoCount'), findsOneWidget);
    });

    testWidgets('no photo counter for single image', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(
            imageUrls: ['https://example.com/single.jpg'],
          ),
        ),
      );
      expect(find.text('image_gallery.photoCount'), findsNothing);
    });

    testWidgets('close button present with correct semantics label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      expect(find.byType(CircleIconButton), findsOneWidget);
      final btn = tester.widget<CircleIconButton>(
        find.byType(CircleIconButton),
      );
      expect(btn.label, 'image_gallery.close');
    });

    testWidgets('close button meets 44x44 touch target', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      final btnSize = tester.getSize(find.byType(CircleIconButton));
      expect(btnSize.width, greaterThanOrEqualTo(44));
      expect(btnSize.height, greaterThanOrEqualTo(44));
    });

    testWidgets('wraps content in AnnotatedRegion for status bar style', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      // Status bar overlay style is scoped via AnnotatedRegion (preferred
      // over imperative SystemChrome push/pop because it auto-restores
      // whatever the parent route had set).
      final annotated = find.byWidgetPredicate(
        (w) => w is AnnotatedRegion<SystemUiOverlayStyle>,
      );
      expect(annotated, findsAtLeastNWidgets(1));
    });

    testWidgets('InteractiveViewer present per image for zoom', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      expect(find.byType(InteractiveViewer), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ImageGalleryPage for each image', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );
      expect(find.byType(ImageGalleryPage), findsAtLeastNWidgets(1));
    });

    testWidgets('show() static method pushes route and dismisses on back', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => ElevatedButton(
                      onPressed:
                          () => ImageGalleryFullscreen.show(
                            context,
                            imageUrls: sampleImageUrls,
                          ),
                      child: const Text('Open'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ImageGalleryFullscreen), findsOneWidget);
    });

    testWidgets('close button taps Navigator.maybePop', (tester) async {
      // Mount inside a Navigator so pop has a parent route to pop from.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => const ImageGalleryFullscreen(
                                    imageUrls: sampleImageUrls,
                                  ),
                            ),
                          ),
                      child: const Text('Open'),
                    ),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ImageGalleryFullscreen), findsOneWidget);

      // Tap close — pops route.
      await tester.tap(find.byIcon(PhosphorIcons.x()));
      await tester.pumpAndSettle();
      expect(find.byType(ImageGalleryFullscreen), findsNothing);
    });

    testWidgets('vertical fling past threshold dismisses the route', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => const ImageGalleryFullscreen(
                                    imageUrls: sampleImageUrls,
                                  ),
                            ),
                          ),
                      child: const Text('Open'),
                    ),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fling down far beyond the 120px threshold — exercises
      // _handleVerticalDragUpdate + _handleVerticalDragEnd dismissal path.
      await tester.drag(find.byType(PageView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.byType(ImageGalleryFullscreen), findsNothing);
    });

    testWidgets(
      'short vertical drag below threshold snaps back and does NOT dismiss',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: ElevatedButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => const ImageGalleryFullscreen(
                                      imageUrls: sampleImageUrls,
                                    ),
                              ),
                            ),
                        child: const Text('Open'),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Drag far below the 120px threshold — snap-back branch fires.
        await tester.drag(find.byType(PageView), const Offset(0, 40));
        await tester.pumpAndSettle();
        expect(find.byType(ImageGalleryFullscreen), findsOneWidget);
      },
    );

    testWidgets('page change updates counter display', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(imageUrls: sampleImageUrls),
        ),
      );

      // Fling horizontally to advance the page — exercises _onPageChanged
      // (reset + setState) and the counter rebuild.
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 2000);
      await tester.pumpAndSettle();

      // No exception, fullscreen still mounted, counter still present.
      expect(tester.takeException(), isNull);
      expect(find.byType(ImageGalleryFullscreen), findsOneWidget);
      expect(find.text('image_gallery.photoCount'), findsOneWidget);
    });

    testWidgets('single-image fullscreen hides counter pill', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: const ImageGalleryFullscreen(
            imageUrls: ['https://example.com/only.jpg'],
          ),
        ),
      );
      expect(find.text('image_gallery.photoCount'), findsNothing);
    });
  });
}
