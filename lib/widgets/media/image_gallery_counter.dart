import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/widgets/media/image_gallery_tokens.dart';

/// Photo counter pill ("1 / 8") for [ImageGallery] and [ImageGalleryFullscreen].
///
/// Wrapped in [ExcludeSemantics] — the counter is decorative, the underlying
/// image semantics already announce "Photo n of total".
class ImageGalleryCounter extends StatelessWidget {
  const ImageGalleryCounter({
    required this.current,
    required this.total,
    super.key,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: ImageGalleryTokens.counterPillHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: ImageGalleryTokens.counterPillPaddingH,
          vertical: ImageGalleryTokens.counterPillPaddingV,
        ),
        decoration: BoxDecoration(
          color: DeelmarktColors.neutral900.withValues(
            alpha: ImageGalleryTokens.counterOpacity,
          ),
          borderRadius: BorderRadius.circular(DeelmarktRadius.full),
        ),
        alignment: Alignment.center,
        child: Text(
          'image_gallery.photoCount'.tr(
            namedArgs: {'current': '$current', 'total': '$total'},
          ),
          style: const TextStyle(
            color: DeelmarktColors.white,
            fontSize: ImageGalleryTokens.counterFontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
