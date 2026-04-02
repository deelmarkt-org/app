/// Size and spacing constants for [DeelBadge] and [DeelBadgeRow].
///
/// Reference: docs/design-system/components.md §Badges
abstract final class DeelBadgeTokens {
  // Badge icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 20;

  // Badge container sizes (icon + padding)
  static const double containerSmall = 24;
  static const double containerMedium = 28;

  // Minimum touch target for tooltip (WCAG 2.5.8)
  static const double minTapTarget = 44;

  // Spacing between badges in a row
  static const double badgeSpacing = 4;

  // Overflow indicator
  static const double overflowFontSize = 12;
}
