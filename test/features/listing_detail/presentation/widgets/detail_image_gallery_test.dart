import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/widgets/buttons/circle_icon_button.dart';

void main() {
  /// [hideFavourite] passes null to onFavouriteTap, hiding the button.
  Widget buildGallery({
    List<String> imageUrls = const [],
    bool isFavourited = false,
    VoidCallback? onFavouriteTap,
    VoidCallback? onBack,
    VoidCallback? onShare,
    bool hideFavourite = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: DetailImageGallery(
            imageUrls: imageUrls,
            isFavourited: isFavourited,
            onFavouriteTap: hideFavourite ? null : (onFavouriteTap ?? () {}),
            onBack: onBack ?? () {},
            onShare: onShare,
          ),
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

    // --- NEW TESTS ---

    testWidgets('favourited state shows filled heart', (tester) async {
      await tester.pumpWidget(buildGallery(isFavourited: true));
      await tester.pump();

      // When isFavourited=true the gallery passes PhosphorIcons.heart(fill)
      // to CircleIconButton. Verify that filled icon is present in the tree.
      final filledHeart = PhosphorIcons.heart(PhosphorIconsStyle.fill);
      expect(find.byIcon(filledHeart), findsOneWidget);
    });

    testWidgets('share button calls onShare', (tester) async {
      var shareCalled = false;
      await tester.pumpWidget(buildGallery(onShare: () => shareCalled = true));
      await tester.pump();

      // Share CircleIconButton carries the shareNetwork icon; tap its InkWell.
      final shareIcon = PhosphorIcons.shareNetwork();
      final shareButton = find.ancestor(
        of: find.byIcon(shareIcon),
        matching: find.byType(InkWell),
      );
      expect(shareButton, findsOneWidget);
      await tester.tap(shareButton);
      expect(shareCalled, isTrue);
    });

    testWidgets('share button hidden when onShare is null', (tester) async {
      // Without onShare: back + favourite = 2 CircleIconButtons.
      await tester.pumpWidget(buildGallery());
      await tester.pump();
      final countWithout =
          tester.widgetList(find.byType(CircleIconButton)).length;

      // With onShare: back + share + favourite = 3 CircleIconButtons.
      await tester.pumpWidget(buildGallery(onShare: () {}));
      await tester.pump();
      final countWith = tester.widgetList(find.byType(CircleIconButton)).length;

      expect(countWithout, 2);
      expect(countWith, 3);
    });

    testWidgets('favourite button hidden when onFavouriteTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(buildGallery(hideFavourite: true));
      await tester.pump();

      // Only back button visible (no favourite, no share)
      expect(tester.widgetList(find.byType(CircleIconButton)).length, 1);
    });
  });
}
