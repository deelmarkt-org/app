/// Cloudinary URL rewriter that appends `f_auto,q_auto,w_{width}` transforms.
///
/// For non-Cloudinary URLs (Supabase Storage, test assets) the URL is returned
/// unchanged — no transform is applied.
class DeelImageUrl {
  const DeelImageUrl._();

  static const String _cloudinaryUploadMarker = '/upload/';

  /// Returns a transformed URL optimised for the given [renderWidth] and
  /// [devicePixelRatio].
  ///
  /// Width is clamped to common breakpoints (160, 320, 480, 640, 960, 1280) so
  /// Cloudinary's CDN can serve the same derived image to multiple devices,
  /// maximising CDN hit-rate and avoiding transform-cache misses.
  static String transform(
    String url, {
    required double renderWidth,
    double devicePixelRatio = 1.0,
  }) {
    if (!url.contains(_cloudinaryUploadMarker)) return url;
    // Already transformed — avoid stacking duplicate segments.
    if (url.contains('/f_auto,q_auto,')) return url;

    final physicalWidth = (renderWidth * devicePixelRatio).ceil();
    final snapped = _snap(physicalWidth);
    final insertAt =
        url.indexOf(_cloudinaryUploadMarker) + _cloudinaryUploadMarker.length;

    return '${url.substring(0, insertAt)}f_auto,q_auto,w_$snapped/${url.substring(insertAt)}';
  }

  static const List<int> _breakpoints = [160, 320, 480, 640, 960, 1280];

  static int _snap(int width) {
    for (final bp in _breakpoints) {
      if (width <= bp) return bp;
    }
    return _breakpoints.last;
  }
}
