import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/widgets/media/image_gallery_counter.dart';
import 'package:deelmarkt/widgets/media/image_gallery_dots.dart';
import 'package:deelmarkt/widgets/media/image_gallery_fullscreen.dart';
import 'package:deelmarkt/widgets/media/image_gallery_page.dart';
import 'package:deelmarkt/widgets/media/image_gallery_tokens.dart';

/// Swipeable image gallery with dot indicators, photo counter, Hero, and
/// customisable overlay slot.
///
/// Supports 0–12 images (excess silently clipped at [ImageGalleryTokens.maxImages]).
/// Empty/null URLs are filtered. `initialPage` is clamped defensively.
///
/// Tap opens [ImageGalleryFullscreen] with pinch/double-tap zoom by default;
/// override via [onTap]. Composable via [overlayBuilder] for feature layers
/// (e.g. listing detail) to add back/share/favourite buttons without
/// duplicating gallery mechanics.
///
/// Example:
/// ```dart
/// // Basic gallery in a card
/// ImageGallery(
///   imageUrls: listing.imageUrls,
///   heroTagPrefix: 'listing-${listing.id}',
/// )
///
/// // Detail page with overlay controls
/// ImageGallery(
///   imageUrls: listing.imageUrls,
///   heroTagPrefix: 'listing-${listing.id}',
///   overlayBuilder: (context, current, total) => DetailOverlayButtons(...),
/// )
/// ```
///
/// `heroTagPrefix` must be unique per listing (e.g. `'listing-123'`) to
/// avoid Hero tag collisions between multiple galleries on the same route.
///
/// Reference: docs/design-system/components.md §ImageGallery
class ImageGallery extends StatefulWidget {
  const ImageGallery({
    required this.imageUrls,
    this.aspectRatio = ImageGalleryTokens.defaultAspectRatio,
    this.heroTagPrefix,
    this.showCounter = true,
    this.showDots = true,
    this.overlayBuilder,
    this.onTap,
    this.onPageChanged,
    this.initialPage = 0,
    this.controller,
    this.cacheWidth,
    super.key,
  });

  final List<String> imageUrls;
  final double aspectRatio;
  final String? heroTagPrefix;
  final bool showCounter;
  final bool showDots;

  /// Optional overlay slot rendered in a [Stack] above the PageView.
  /// Receives the current page index and the total image count.
  final Widget Function(BuildContext context, int current, int total)?
  overlayBuilder;

  /// Tap handler. When null, tapping an image opens [ImageGalleryFullscreen].
  final VoidCallback? onTap;

  final ValueChanged<int>? onPageChanged;
  final int initialPage;

  /// Optional external [PageController]. When provided, the parent owns
  /// disposal. When null, this widget creates and disposes its own.
  final PageController? controller;

  /// Optional cache width for memory-efficient image decoding.
  final int? cacheWidth;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late final List<String> _urls;
  late final PageController _controller;
  late final bool _ownsController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    // Defensive filtering: strip empty strings, cap at max.
    _urls = widget.imageUrls
        .where((u) => u.trim().isNotEmpty)
        .take(ImageGalleryTokens.maxImages)
        .toList(growable: false);

    // Defensive clamping of initialPage.
    final clamped =
        _urls.isEmpty ? 0 : widget.initialPage.clamp(0, _urls.length - 1);
    _currentPage = clamped;

    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = PageController(initialPage: clamped);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (_urls.isEmpty) return;
    ImageGalleryFullscreen.show(
      context,
      imageUrls: _urls,
      initialIndex: _currentPage,
      heroTagPrefix: widget.heroTagPrefix,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_urls.isEmpty) _buildEmpty(context) else _buildPageView(),
          if (widget.showDots && _urls.length > 1)
            ImageGalleryDots(count: _urls.length, currentIndex: _currentPage),
          if (widget.showCounter && _urls.isNotEmpty)
            Positioned(
              bottom: ImageGalleryTokens.counterBottomOffset,
              right: ImageGalleryTokens.counterRightOffset,
              child: ImageGalleryCounter(
                current: _currentPage + 1,
                total: _urls.length,
              ),
            ),
          if (widget.overlayBuilder != null)
            widget.overlayBuilder!(context, _currentPage, _urls.length),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: PageView.builder(
        controller: _controller,
        itemCount: _urls.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return ImageGalleryPage(
            imageUrl: _urls[index],
            index: index,
            total: _urls.length,
            heroTag:
                widget.heroTagPrefix == null
                    ? null
                    : '${widget.heroTagPrefix}-$index',
            cacheWidth: widget.cacheWidth,
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'image_gallery.noImages'.tr(),
      child: Container(
        color:
            isDark
                ? DeelmarktColors.darkSurfaceElevated
                : DeelmarktColors.neutral100,
        child: Center(
          child: Icon(
            PhosphorIcons.image(PhosphorIconsStyle.duotone),
            size: DeelmarktIconSize.hero,
            color:
                isDark
                    ? DeelmarktColors.darkOnSurfaceSecondary
                    : DeelmarktColors.neutral500,
          ),
        ),
      ),
    );
  }
}
