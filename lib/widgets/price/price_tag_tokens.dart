/// Dimension constants for [PriceTag].
///
/// Reference: docs/design-system/components.md §PriceTag
/// Reference: docs/design-system/tokens.md §Typography (price, priceSm)
abstract final class PriceTagTokens {
  /// Font size for [PriceTagSize.normal] — matches `DeelmarktTypography.price`.
  static const double normalFontSize = 20;

  /// Font size for [PriceTagSize.small] — matches `DeelmarktTypography.priceSm`.
  static const double smallFontSize = 16;

  /// Font size for BTW subtitle.
  static const double btwFontSize = 12;

  /// Horizontal gap between strikethrough original price and current price.
  static const double strikethroughGap = 6;

  /// Vertical gap between price row and BTW subtitle.
  static const double btwTopGap = 2;
}
