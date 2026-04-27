import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/services/image_cache_manager.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/core/utils/deel_image_url.dart';

/// Image component for [DeelCard] with Hero transition, loading, and error states.
///
/// Uses [CachedNetworkImage] with [DeelCacheManager] for disk-backed caching and
/// [DeelImageUrl] for Cloudinary `f_auto,q_auto,w_N` transforms (ADR-022).
///
/// The image is wrapped in [ExcludeSemantics] because [DeelCard] already provides
/// a comprehensive semantic label (price + title) for the whole card. Exposing the
/// unlabelled image node separately would cause TalkBack/VoiceOver to announce
/// "image" without context, which is worse than omitting it.
class DeelCardImage extends ConsumerStatefulWidget {
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
  ConsumerState<DeelCardImage> createState() => _DeelCardImageState();

  /// Test hook for [_reportImageError]. Not part of the public API.
  @visibleForTesting
  static void reportImageError(String url, Object error) =>
      _reportImageError(url, error);

  /// Test hook for [_extractHttpStatus]. Not part of the public API.
  @visibleForTesting
  static int? extractHttpStatus(Object error) => _extractHttpStatus(error);

  /// Captures `image_load_failed` in Sentry with a hashed URL (no PII).
  static void _reportImageError(String url, Object error) {
    final urlHash = sha256.convert(utf8.encode(url)).toString();
    final httpStatus = _extractHttpStatus(error);
    Sentry.captureMessage(
      'image_load_failed',
      level: SentryLevel.warning,
      withScope: (scope) {
        scope.setTag('url_hash', urlHash);
        if (httpStatus != null) scope.setTag('http_status', '$httpStatus');
      },
    );
  }

  static int? _extractHttpStatus(Object error) {
    final message = error.toString();
    final match = RegExp(r'statusCode[=: ]+(\d{3})').firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}

class _DeelCardImageState extends ConsumerState<DeelCardImage> {
  // GH #221 — image_load trace covers `cached_network_image` fetch from
  // build entry to first decoded frame (success path) or errorWidget
  // invocation (failure path). Single trace per widget instance; the
  // `_stopped` flag makes stop() idempotent so re-decodes (cache-warm
  // re-rendering of the same provider) do not double-stop the handle.
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
    // Safety net: a widget disposed mid-fetch (scrolled out of view, list
    // refresh) must not leak the trace handle. Stop is idempotent.
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
    final effectiveBorderRadius =
        widget.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(DeelmarktRadius.xl));
    final dpr = MediaQuery.of(context).devicePixelRatio;

    Widget image = ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final transformedUrl = DeelImageUrl.transform(
              widget.imageUrl,
              renderWidth: constraints.maxWidth,
              devicePixelRatio: dpr,
            );
            return ClipRRect(
              borderRadius: effectiveBorderRadius,
              child: CachedNetworkImage(
                imageUrl: transformedUrl,
                cacheManager: DeelCacheManager(),
                fit: BoxFit.cover,
                fadeInDuration: duration,
                fadeInCurve: DeelmarktAnimation.curveStandard,
                imageBuilder: (context, imageProvider) {
                  // First decode complete → trace ends here on success.
                  _stopTraceOnce();
                  return Image(image: imageProvider, fit: BoxFit.cover);
                },
                placeholder: (context, url) => _placeholder(context),
                errorWidget: (context, url, error) {
                  // Decode failed → trace ends here on error path.
                  _stopTraceOnce();
                  DeelCardImage._reportImageError(url, error);
                  return _placeholder(context);
                },
              ),
            );
          },
        ),
      ),
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
          size: 32,
        ),
      ),
    );
  }
}
