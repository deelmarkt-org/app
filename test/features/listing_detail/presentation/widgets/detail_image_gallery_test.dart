import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';

void main() {
  Widget buildGallery({
    List<String> imageUrls = const [],
    bool isFavourited = false,
    VoidCallback? onFavouriteTap,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: DetailImageGallery(
          imageUrls: imageUrls,
          isFavourited: isFavourited,
          onFavouriteTap: onFavouriteTap ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  group('DetailImageGallery', () {
    testWidgets('renders placeholder when no images', (tester) async {
      await tester.pumpWidget(buildGallery());
      await tester.pump();

      // No PageView when no images
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders PageView with images', (tester) async {
      await tester.pumpWidget(
        buildGallery(imageUrls: ['https://example.com/1.jpg']),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('back button calls onBack', (tester) async {
      var backCalled = false;
      await tester.pumpWidget(buildGallery(onBack: () => backCalled = true));
      await tester.pump();

      // First InkWell in the stack is the back button
      await tester.tap(find.byType(InkWell).first);
      expect(backCalled, isTrue);
    });

    testWidgets('favourite button calls onFavouriteTap', (tester) async {
      var favCalled = false;
      await tester.pumpWidget(
        buildGallery(onFavouriteTap: () => favCalled = true),
      );
      await tester.pump();

      // Last InkWell is the favourite button
      await tester.tap(find.byType(InkWell).last);
      expect(favCalled, isTrue);
    });

    testWidgets('back and favourite buttons are 44x44', (tester) async {
      await tester.pumpWidget(buildGallery());
      await tester.pump();

      final buttons = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 44 && w.height == 44,
      );
      expect(buttons, findsNWidgets(2));
    });

    testWidgets('does not show dots when single image', (tester) async {
      await tester.pumpWidget(
        buildGallery(imageUrls: ['https://example.com/1.jpg']),
      );
      await tester.pump();

      // AnimatedContainer is used for dots; with 1 image, none should appear
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('shows dots when multiple images', (tester) async {
      await tester.pumpWidget(
        buildGallery(
          imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });
  });
}
