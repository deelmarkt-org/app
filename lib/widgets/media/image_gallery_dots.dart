import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/widgets/media/image_gallery_tokens.dart';

/// Animated dot indicators for [ImageGallery].
///
/// Shows one dot per image; the active dot is visually larger.
/// Wrapped in [ExcludeSemantics] — dots are decorative.
class ImageGalleryDots extends StatelessWidget {
  const ImageGalleryDots({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.quick,
      reduceMotion: reduceMotion,
    );

    return Positioned(
      bottom: ImageGalleryTokens.dotsBottomOffset,
      left: 0,
      right: 0,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final isActive = i == currentIndex;
            return AnimatedContainer(
              duration: duration,
              margin: const EdgeInsets.symmetric(
                horizontal: ImageGalleryTokens.dotSpacing,
              ),
              width:
                  isActive
                      ? ImageGalleryTokens.dotActiveSize
                      : ImageGalleryTokens.dotInactiveSize,
              height:
                  isActive
                      ? ImageGalleryTokens.dotActiveSize
                      : ImageGalleryTokens.dotInactiveSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive
                        ? DeelmarktColors.white
                        : DeelmarktColors.white.withValues(alpha: 0.5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
