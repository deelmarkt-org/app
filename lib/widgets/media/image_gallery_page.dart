import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';

/// Single-image page used by [ImageGallery] and [ImageGalleryFullscreen].
///
/// Mirrors the canonical image pattern from [DeelCardImage]:
/// - `frameBuilder` for fade-in when the image arrives
/// - `errorBuilder` for graceful placeholder on network failure
/// - Optional [Hero] wrap for list → detail transitions
/// - `cacheWidth` parameter for memory-efficient decoding of large images
///
/// Carries `index` + `total` so each image can announce itself to
/// screen readers as "Photo n of total".
class ImageGalleryPage extends StatelessWidget {
  const ImageGalleryPage({
    required this.imageUrl,
    required this.index,
    required this.total,
    this.heroTag,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    super.key,
  });

  final String imageUrl;
  final int index;
  final int total;
  final String? heroTag;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.standard,
      reduceMotion: reduceMotion,
    );

    Widget image = Image.network(
      imageUrl,
      fit: fit,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return AnimatedOpacity(
            opacity: 1.0,
            duration: duration,
            curve: DeelmarktAnimation.curveStandard,
            child: child,
          );
        }
        return _placeholder(context);
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );

    image = Semantics(
      image: true,
      label: 'image_gallery.photoSemantics'.tr(
        namedArgs: {'current': '${index + 1}', 'total': '$total'},
      ),
      child: image,
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return image;
  }

  Widget _placeholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color:
          isDark
              ? DeelmarktColors.darkSurfaceElevated
              : DeelmarktColors.neutral100,
      child: Center(
        child: Icon(
          PhosphorIcons.image(PhosphorIconsStyle.duotone),
          color:
              isDark
                  ? DeelmarktColors.darkOnSurfaceSecondary
                  : DeelmarktColors.neutral500,
          size: DeelmarktIconSize.hero,
        ),
      ),
    );
  }
}
