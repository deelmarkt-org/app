import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';

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
class ImageGalleryPage extends ConsumerStatefulWidget {
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
  ConsumerState<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends ConsumerState<ImageGalleryPage> {
  // GH #221 — image_load trace covers Image.network fetch from build entry
  // to first decoded frame (success path) or errorBuilder invocation (failure
  // path). Single trace per widget instance; _stopped flag makes stop()
  // idempotent so re-renders don't double-stop the handle.
  PerformanceTraceHandle? _traceHandle;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _traceHandle = ref
        .read(performanceTracerProvider)
        .start(TraceNames.imageLoad);
  }

  void _stopTraceOnce() {
    if (_stopped) return;
    _stopped = true;
    final handle = _traceHandle;
    if (handle != null) unawaited(handle.stop());
  }

  @override
  void dispose() {
    // Safety net: widget disposed mid-fetch (swipe away, gallery close).
    _stopTraceOnce();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.standard,
      reduceMotion: reduceMotion,
    );

    Widget image = Image.network(
      widget.imageUrl,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          // First decode complete → trace ends on success path.
          _stopTraceOnce();
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
        // Decode failed → trace ends on error path.
        _stopTraceOnce();
        return _placeholder(context);
      },
    );

    image = Semantics(
      image: true,
      label: 'image_gallery.photoSemantics'.tr(
        namedArgs: {
          'current': '${widget.index + 1}',
          'total': '${widget.total}',
        },
      ),
      child: image,
    );

    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
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
