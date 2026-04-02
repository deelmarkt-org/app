import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/circle_icon_button.dart';

/// Swipeable image gallery with dot indicators, back/share/heart overlay.
///
/// Aspect ratio 4:3, supports 1–12 images.
/// Touch targets 44×44px per WCAG / EAA requirements.
class DetailImageGallery extends StatefulWidget {
  const DetailImageGallery({
    required this.imageUrls,
    required this.isFavourited,
    required this.onFavouriteTap,
    required this.onBack,
    this.onShare,
    super.key,
  });

  final List<String> imageUrls;
  final bool isFavourited;
  final VoidCallback onFavouriteTap;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  State<DetailImageGallery> createState() => _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<DetailImageGallery> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.imageUrls.isNotEmpty;
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImages) _buildPageView(theme) else _placeholder(theme),
          _buildOverlayButtons(),
          if (hasImages && widget.imageUrls.length > 1) _buildDotIndicators(),
        ],
      ),
    );
  }

  Widget _buildPageView(ThemeData theme) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.imageUrls.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        return Semantics(
          image: true,
          label: 'listing_detail.photoCount'.tr(
            namedArgs: {
              'current': '${index + 1}',
              'total': '${widget.imageUrls.length}',
            },
          ),
          child: Image.network(
            widget.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(theme),
          ),
        );
      },
    );
  }

  Widget _buildOverlayButtons() {
    final favIcon =
        widget.isFavourited
            ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
            : PhosphorIcons.heart();
    final favLabel =
        widget.isFavourited
            ? 'listing_card.removeFavourite'.tr()
            : 'listing_card.addFavourite'.tr();

    return Stack(
      children: [
        Positioned(
          top: Spacing.s2,
          left: Spacing.s2,
          child: CircleIconButton(
            icon: PhosphorIcons.arrowLeft(),
            onTap: widget.onBack,
            label: 'nav.back'.tr(),
          ),
        ),
        Positioned(
          top: Spacing.s2,
          right: Spacing.s2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onShare != null) ...[
                CircleIconButton(
                  icon: PhosphorIcons.shareNetwork(),
                  onTap: widget.onShare!,
                  label: 'action.share'.tr(),
                ),
                const SizedBox(width: Spacing.s2),
              ],
              CircleIconButton(
                icon: favIcon,
                onTap: widget.onFavouriteTap,
                label: favLabel,
                iconColor: widget.isFavourited ? DeelmarktColors.error : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicators() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Positioned(
      bottom: Spacing.s3,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.imageUrls.length, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: DeelmarktAnimation.resolve(
              DeelmarktAnimation.quick,
              reduceMotion: reduceMotion,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
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
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Icon(
        PhosphorIcons.image(),
        size: DeelmarktIconSize.hero,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
