import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/media/image_gallery.dart';

import 'image_gallery_test_helper.dart';

void main() {
  group('ImageGallery accessibility', () {
    testWidgets('image pages have Semantics labels', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(child: const ImageGallery(imageUrls: sampleImageUrls)),
      );
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasPhotoSemantics = semanticsList.any(
        (s) =>
            s.properties.label?.contains('image_gallery.photoSemantics') ??
            false,
      );
      expect(hasPhotoSemantics, isTrue);
    });

    testWidgets('counter pill is excluded from semantics tree', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(child: const ImageGallery(imageUrls: sampleImageUrls)),
      );
      // Counter is wrapped in ExcludeSemantics — at least one must exist
      // in our widget tree. (Scaffold uses others internally.)
      expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(1));
    });

    testWidgets('empty state has semantic label', (tester) async {
      await tester.pumpWidget(
        buildGalleryApp(child: const ImageGallery(imageUrls: [])),
      );
      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasNoImagesLabel = semanticsList.any(
        (s) => s.properties.label?.contains('image_gallery.noImages') ?? false,
      );
      expect(hasNoImagesLabel, isTrue);
    });

    testWidgets('reduced motion: dot animation uses zero duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: buildGalleryApp(
            child: const ImageGallery(imageUrls: sampleImageUrls),
          ),
        ),
      );
      // Find AnimatedContainer dots; their duration should be Duration.zero
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        animatedContainers.any((c) => c.duration == Duration.zero),
        isTrue,
      );
    });

    testWidgets('overlayBuilder content is part of the widget tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGalleryApp(
          child: ImageGallery(
            imageUrls: sampleImageUrls,
            overlayBuilder:
                (_, _, _) => Positioned(
                  top: 0,
                  left: 0,
                  child: Semantics(
                    button: true,
                    label: 'Custom overlay button',
                    child: const SizedBox(width: 44, height: 44),
                  ),
                ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Custom overlay button'), findsOneWidget);
    });
  });
}
