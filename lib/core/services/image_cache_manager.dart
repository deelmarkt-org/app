import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for all network images loaded via [CachedNetworkImage].
///
/// Bounded at 200 objects / 50 MB to stay within mid-tier Android budgets
/// (Galaxy A32 class, ~300 MB total app allocation per ADR-022).
class DeelCacheManager extends CacheManager with ImageCacheManager {
  factory DeelCacheManager() => _instance;

  DeelCacheManager._()
    : super(
        Config(
          _cacheKey,
          stalePeriod: _stalePeriod,
          maxNrOfCacheObjects: _maxObjects,
        ),
      );

  static final DeelCacheManager _instance = DeelCacheManager._();

  static const String _cacheKey = '.deel_image_cache';
  static const Duration _stalePeriod = Duration(days: 7);
  static const int _maxObjects = 200;

  /// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// Caps Flutter's in-memory decoded-image store so large listing grids cannot
  /// OOM devices with limited RAM.
  static void configureMemoryCache() {
    PaintingBinding.instance.imageCache
      ..maximumSize = 100
      ..maximumSizeBytes = 50 * 1024 * 1024;
  }
}
