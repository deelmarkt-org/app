import 'package:deelmarkt/core/design_system/radius.dart';

/// Size and dimension constants for [DeelAvatar].
///
/// Reference: docs/design-system/components.md §Avatar
abstract final class DeelAvatarTokens {
  // Avatar diameters
  static const double sizeSmall = 32;
  static const double sizeMedium = 48;
  static const double sizeLarge = 80;

  // Full circular radius
  static const double borderRadius = DeelmarktRadius.full;

  // Edit overlay
  static const double editOverlayOpacity = 0.5;
  static const double editIconSize = 24;

  // Badge offset from bottom-right
  static const double badgeOffset = 0;
}
