import 'package:deelmarkt/core/design_system/radius.dart';

/// Dimension constants for [DeelCard] variants.
///
/// Reference: docs/design-system/components.md §Listing Card
abstract final class DeelCardTokens {
  // Card border radius
  static const double borderRadius = DeelmarktRadius.xl;

  // Grid variant
  static const double gridImageAspectWidth = 4;
  static const double gridImageAspectHeight = 3;

  // List variant
  static const double listThumbnailSize = 120;

  // Favourite button
  static const double favouriteTapTarget = 44;
  static const double favouriteIconSize = 20;

  // Price typography
  static const double priceFontSize = 16;

  // Title
  static const int titleMaxLines = 2;

  // Badge position offset from top-right
  static const double badgeTopOffset = 8;
  static const double badgeRightOffset = 8;
}
