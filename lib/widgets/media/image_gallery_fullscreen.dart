import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/circle_icon_button.dart';
import 'package:deelmarkt/widgets/media/image_gallery_counter.dart';
import 'package:deelmarkt/widgets/media/image_gallery_tokens.dart';
import 'package:deelmarkt/widgets/media/image_gallery_zoomable_page.dart';

/// Fullscreen image viewer with pinch-to-zoom, double-tap zoom, and
/// drag-to-dismiss.
///
/// - Pinch to zoom (1x–4x) via [InteractiveViewer]
/// - Double-tap toggles 1x ↔ 2x with haptic feedback
/// - Drag down to dismiss with opacity transition
/// - Status bar style preserved and restored on exit
/// - PageView swiping disabled while zoomed (gesture disambiguation)
/// - Zoom reset on page change
class ImageGalleryFullscreen extends StatefulWidget {
  const ImageGalleryFullscreen({
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
    super.key,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  /// Opens the fullscreen gallery as an opaque page route.
  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        barrierColor: DeelmarktColors.neutral900,
        transitionDuration: DeelmarktAnimation.standard,
        reverseTransitionDuration: DeelmarktAnimation.standard,
        pageBuilder:
            (_, _, _) => ImageGalleryFullscreen(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
              heroTagPrefix: heroTagPrefix,
            ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ImageGalleryFullscreen> createState() => _ImageGalleryFullscreenState();
}

class _ImageGalleryFullscreenState extends State<ImageGalleryFullscreen> {
  late final PageController _pageController;
  late int _currentPage;
  final Map<int, GlobalKey<ImageGalleryZoomablePageState>> _pageKeys = {};
  double _dragOffset = 0;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.imageUrls.isNotEmpty,
      'ImageGalleryFullscreen requires at least one image',
    );
    _currentPage =
        widget.imageUrls.isEmpty
            ? 0
            : widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GlobalKey<ImageGalleryZoomablePageState> _keyFor(int index) {
    return _pageKeys.putIfAbsent(
      index,
      GlobalKey<ImageGalleryZoomablePageState>.new,
    );
  }

  void _onPageChanged(int index) {
    // Reset zoom on previous page to avoid stale state when swiping back.
    _pageKeys[_currentPage]?.currentState?.reset();
    setState(() {
      _currentPage = index;
      _isZoomed = false;
    });
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > ImageGalleryTokens.dragDismissThreshold) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset / ImageGalleryTokens.dragOpacityRange))
        .clamp(ImageGalleryTokens.dragOpacityFloor, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Semantics(
        container: true,
        label: 'image_gallery.fullscreenLabel'.tr(),
        child: Scaffold(
          backgroundColor: DeelmarktColors.neutral900.withValues(
            alpha: opacity,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        _isZoomed
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: widget.imageUrls.length,
                    itemBuilder:
                        (context, index) => ImageGalleryZoomablePage(
                          key: _keyFor(index),
                          imageUrl: widget.imageUrls[index],
                          index: index,
                          total: widget.imageUrls.length,
                          onZoomChanged: _onZoomChanged,
                          heroTag:
                              widget.heroTagPrefix == null
                                  ? null
                                  : '${widget.heroTagPrefix}-$index',
                        ),
                  ),
                ),
              ),
              Positioned(
                top:
                    MediaQuery.of(context).padding.top +
                    ImageGalleryTokens.closeButtonTopOffset,
                right: ImageGalleryTokens.closeButtonRightOffset,
                child: CircleIconButton(
                  icon: PhosphorIcons.x(),
                  onTap: () => Navigator.of(context).maybePop(),
                  label: 'image_gallery.close'.tr(),
                ),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + Spacing.s6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ImageGalleryCounter(
                      current: _currentPage + 1,
                      total: widget.imageUrls.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
