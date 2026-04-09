import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/circle_icon_button.dart';
import 'package:deelmarkt/widgets/media/image_gallery.dart';

/// Swipeable image gallery with overlay buttons for listing detail.
///
/// Composes [ImageGallery] via `overlayBuilder` for back/share/favourite
/// controls. Tap opens fullscreen viewer with pinch-zoom.
///
/// Aspect ratio 4:3, supports 1–12 images.
/// Touch targets 44×44px per WCAG / EAA requirements.
class DetailImageGallery extends StatelessWidget {
  const DetailImageGallery({
    required this.imageUrls,
    this.isFavourited = false,
    this.onFavouriteTap,
    required this.onBack,
    this.onShare,
    this.heroTagPrefix,
    super.key,
  });

  final List<String> imageUrls;
  final bool isFavourited;

  /// When null, the favourite button is hidden (e.g. sold listings).
  final VoidCallback? onFavouriteTap;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  /// Hero tag prefix for shared element transitions from card → detail.
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'listing_detail.imageGallery'.tr(),
      container: true,
      child: ImageGallery(
        imageUrls: imageUrls,
        heroTagPrefix: heroTagPrefix,
        showCounter: false,
        overlayBuilder: (context, current, total) => _buildOverlayButtons(),
      ),
    );
  }

  Widget _buildOverlayButtons() {
    final favIcon =
        isFavourited
            ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
            : PhosphorIcons.heart();
    final favLabel =
        isFavourited
            ? 'listing_card.removeFavourite'.tr()
            : 'listing_card.addFavourite'.tr();

    return Stack(
      children: [
        Positioned(
          top: Spacing.s2,
          left: Spacing.s2,
          child: CircleIconButton(
            icon: PhosphorIcons.arrowLeft(),
            onTap: onBack,
            label: 'nav.back'.tr(),
          ),
        ),
        Positioned(
          top: Spacing.s2,
          right: Spacing.s2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onShare != null) ...[
                CircleIconButton(
                  icon: PhosphorIcons.shareNetwork(),
                  onTap: onShare!,
                  label: 'action.share'.tr(),
                ),
                const SizedBox(width: Spacing.s2),
              ],
              if (onFavouriteTap != null)
                CircleIconButton(
                  icon: favIcon,
                  onTap: onFavouriteTap!,
                  label: favLabel,
                  iconColor: isFavourited ? DeelmarktColors.error : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
