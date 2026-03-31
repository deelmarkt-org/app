import 'package:deelmarkt/core/design_system/spacing.dart';

import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Design tokens for [DeelButton] sizes.
/// Reference: docs/design-system/components.md §Buttons
abstract final class DeelButtonTokens {
  // ── Heights ──────────────────────────────────────────────────────────

  /// Large button height: 52px
  static const double heightLarge = 52;

  /// Medium button height: 44px (WCAG minimum touch target)
  static const double heightMedium = 44;

  /// Small button height: 36px
  static const double heightSmall = 36;

  // ── Font sizes ───────────────────────────────────────────────────────

  /// Large button font: 16px
  static const double fontLarge = 16;

  /// Medium button font: 14px
  static const double fontMedium = 14;

  /// Small button font: 13px
  static const double fontSmall = 13;

  // ── Icon sizes ───────────────────────────────────────────────────────

  /// Large button icon: 20px
  static const double iconLarge = 20;

  /// Medium button icon: 18px
  static const double iconMedium = 18;

  /// Small button icon: 16px
  static const double iconSmall = 16;

  // ── Resolvers ────────────────────────────────────────────────────────

  /// Resolve min height for given size.
  static double heightFor(DeelButtonSize size) => switch (size) {
    DeelButtonSize.large => heightLarge,
    DeelButtonSize.medium => heightMedium,
    DeelButtonSize.small => heightSmall,
  };

  /// Resolve horizontal padding for given size.
  static double paddingFor(DeelButtonSize size) => switch (size) {
    DeelButtonSize.large => Spacing.s6,
    DeelButtonSize.medium => Spacing.s4,
    DeelButtonSize.small => Spacing.s3,
  };

  /// Resolve font size for given size.
  static double fontSizeFor(DeelButtonSize size) => switch (size) {
    DeelButtonSize.large => fontLarge,
    DeelButtonSize.medium => fontMedium,
    DeelButtonSize.small => fontSmall,
  };

  /// Resolve icon size for given size.
  static double iconSizeFor(DeelButtonSize size) => switch (size) {
    DeelButtonSize.large => iconLarge,
    DeelButtonSize.medium => iconMedium,
    DeelButtonSize.small => iconSmall,
  };
}
