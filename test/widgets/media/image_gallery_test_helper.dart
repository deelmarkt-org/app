import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps a gallery widget in a themed [MaterialApp] inside a
/// [ProviderScope]. The scope is required because [ImageGalleryPage] consumes
/// the [performanceTracerProvider] after GH #221 Phase B wiring.
Widget buildGalleryApp({required Widget child, ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

/// Sample image URLs for tests (never actually fetched — errorBuilder
/// handles network failure gracefully).
const sampleImageUrls = [
  'https://example.com/img1.jpg',
  'https://example.com/img2.jpg',
  'https://example.com/img3.jpg',
];
