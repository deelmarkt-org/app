import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/widgets/media/image_gallery_page.dart';
import 'package:deelmarkt/widgets/media/image_gallery_tokens.dart';

/// A zoomable page wrapper used by [ImageGalleryFullscreen].
///
/// Wraps [ImageGalleryPage] in an [InteractiveViewer] with pinch-to-zoom
/// (1x–4x) plus double-tap toggle between 1x and 2x. Emits
/// [onZoomChanged] whenever the zoom state crosses the zoomed threshold
/// so the parent can disable PageView swiping.
class ImageGalleryZoomablePage extends StatefulWidget {
  const ImageGalleryZoomablePage({
    required this.imageUrl,
    required this.index,
    required this.total,
    required this.onZoomChanged,
    this.heroTag,
    super.key,
  });

  final String imageUrl;
  final int index;
  final int total;
  final ValueChanged<bool> onZoomChanged;
  final String? heroTag;

  @override
  State<ImageGalleryZoomablePage> createState() =>
      ImageGalleryZoomablePageState();
}

class ImageGalleryZoomablePageState extends State<ImageGalleryZoomablePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _doubleTapController;
  Animation<Matrix4>? _doubleTapAnim;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
      vsync: this,
      duration: DeelmarktAnimation.standard,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }

  /// Reset the zoom transformation to identity. Called by the parent
  /// when the user swipes to a new page.
  void reset() {
    _controller.value = Matrix4.identity();
    if (_isZoomed) {
      setState(() => _isZoomed = false);
      widget.onZoomChanged(false);
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      HapticFeedback.lightImpact();
    }

    final Matrix4 end;
    if (currentScale > 1.01) {
      end = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const scale = ImageGalleryTokens.fullscreenDoubleTapScale;
      end =
          Matrix4.identity()
            ..translateByDouble(
              -position.dx * (scale - 1),
              -position.dy * (scale - 1),
              0,
              1,
            )
            ..scaleByDouble(scale, scale, scale, 1);
    }

    _doubleTapAnim = Matrix4Tween(begin: _controller.value, end: end).animate(
      CurvedAnimation(
        parent: _doubleTapController,
        curve: DeelmarktAnimation.curveStandard,
      ),
    );
    _doubleTapAnim!.addListener(() {
      _controller.value = _doubleTapAnim!.value;
    });
    _doubleTapController.forward(from: 0).whenComplete(() {
      final zoomed = end != Matrix4.identity();
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged(zoomed);
    });
  }

  void _onInteractionUpdate() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: ImageGalleryTokens.fullscreenMinScale,
          maxScale: ImageGalleryTokens.fullscreenMaxScale,
          onInteractionUpdate: (_) => _onInteractionUpdate(),
          child: Center(
            child: ImageGalleryPage(
              imageUrl: widget.imageUrl,
              index: widget.index,
              total: widget.total,
              heroTag: widget.heroTag,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
