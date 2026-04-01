import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';

/// Image component for [DeelCard] with Hero transition, loading, and error states.
class DeelCardImage extends StatelessWidget {
  const DeelCardImage({
    required this.imageUrl,
    required this.aspectRatio,
    this.heroTag,
    this.borderRadius,
    super.key,
  });

  final String imageUrl;
  final double aspectRatio;
  final String? heroTag;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.standard,
      reduceMotion: reduceMotion,
    );
    final effectiveBorderRadius =
        borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(DeelmarktRadius.xl));

    Widget image = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
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
          errorBuilder: (context, error, stackTrace) {
            return _placeholder(context);
          },
        ),
      ),
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
          size: 32,
        ),
      ),
    );
  }
}
