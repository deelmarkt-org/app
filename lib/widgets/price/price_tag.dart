import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/price/price_tag_tokens.dart';

/// Formatted Euro price display with optional BTW and strikethrough.
///
/// Centralises price rendering through [Formatters.euroFromCents] and
/// uses tabular figures for column alignment in lists. A zero price
/// displays "Gratis" / "Free" via l10n.
///
/// Wrapped in [MergeSemantics] so the screen reader produces a single
/// human-readable utterance (e.g. "45 euro, was 60 euro, incl. BTW").
///
/// Example:
/// ```dart
/// // Simple listing card price
/// PriceTag(priceInCents: 4500)
///
/// // Detail page with BTW subtitle
/// PriceTag(
///   priceInCents: 4500,
///   showBtw: true,
/// )
///
/// // Discounted offer with strikethrough original price
/// PriceTag(
///   priceInCents: 3500,
///   originalPriceInCents: 4500,
/// )
/// ```
///
/// Reference: docs/design-system/components.md §PriceTag
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.priceInCents,
    this.originalPriceInCents,
    this.size = PriceTagSize.normal,
    this.showBtw = false,
    this.btwInclusive = true,
    super.key,
  });

  /// Current price in cents (e.g. 4500 = €45,00).
  final int priceInCents;

  /// Optional original price in cents. When set and greater than
  /// [priceInCents], the original is rendered with strikethrough
  /// alongside the current discounted price.
  final int? originalPriceInCents;

  /// Visual size variant.
  final PriceTagSize size;

  /// Whether to show the "incl./excl. BTW" subtitle.
  final bool showBtw;

  /// Whether the price includes BTW (true) or excludes it (false).
  /// Ignored when [showBtw] is false.
  final bool btwInclusive;

  bool get _isFree => priceInCents == 0;
  bool get _isDiscounted =>
      originalPriceInCents != null && originalPriceInCents! > priceInCents;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle =
        size == PriceTagSize.normal
            ? DeelmarktTypography.price
            : DeelmarktTypography.priceSm;

    final primaryColor =
        isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary;
    final mutedColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

    // Current price text color: primary when free OR discounted,
    // default (theme foreground) otherwise.
    final currentColor =
        (_isFree || _isDiscounted)
            ? primaryColor
            : (isDark
                ? DeelmarktColors.darkOnSurface
                : DeelmarktColors.neutral900);

    const tabular = [FontFeature.tabularFigures()];

    final currentStyle = baseStyle.copyWith(
      color: currentColor,
      fontFeatures: tabular,
    );

    final strikethroughStyle = baseStyle.copyWith(
      color: mutedColor,
      decoration: TextDecoration.lineThrough,
      decorationColor: mutedColor,
      fontSize: PriceTagTokens.strikethroughFontSize,
      fontWeight: FontWeight.w600,
      fontFeatures: tabular,
    );

    final btwStyle = TextStyle(
      fontSize: PriceTagTokens.btwFontSize,
      fontWeight: FontWeight.w500,
      color: mutedColor,
      height: 1.33,
    );

    return MergeSemantics(
      child: Semantics(
        label: _buildSemanticsLabel(),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDiscounted)
                _buildDiscountedRow(currentStyle, strikethroughStyle)
              else
                Text(_displayText(), style: currentStyle),
              if (showBtw) ...[
                const SizedBox(height: PriceTagTokens.btwTopGap),
                Text(_btwText(), style: btwStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountedRow(TextStyle current, TextStyle strikethrough) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(_displayText(), style: current),
        const SizedBox(width: PriceTagTokens.strikethroughGap),
        Text(
          Formatters.euroFromCents(originalPriceInCents!),
          style: strikethrough,
        ),
      ],
    );
  }

  String _displayText() {
    if (_isFree) return 'price_tag.free'.tr();
    return Formatters.euroFromCents(priceInCents);
  }

  String _btwText() {
    return btwInclusive ? 'price_tag.inclBtw'.tr() : 'price_tag.exclBtw'.tr();
  }

  String _buildSemanticsLabel() {
    if (_isFree) return 'price_tag.semanticsFree'.tr();

    final priceText = _humanReadableEuros(priceInCents);
    if (_isDiscounted) {
      final originalText = _humanReadableEuros(originalPriceInCents!);
      return 'price_tag.semanticsDiscounted'.tr(
        namedArgs: {'price': priceText, 'original': originalText},
      );
    }
    return 'price_tag.semanticsPrice'.tr(namedArgs: {'price': priceText});
  }

  /// Formats a cent value for screen reader announcement.
  ///
  /// Whole-euro amounts drop the decimals so TTS reads "forty-five euro"
  /// instead of "forty-five point zero zero euro". Addresses the Gemini
  /// code review recommendation for natural VoiceOver / TalkBack output.
  static String _humanReadableEuros(int cents) {
    final euros = cents / 100;
    return euros.toStringAsFixed(cents % 100 == 0 ? 0 : 2);
  }
}

/// Visual size variant for [PriceTag].
///
/// - [normal] uses `DeelmarktTypography.price` (20px bold) — detail pages
/// - [small] uses `DeelmarktTypography.priceSm` (16px bold) — cards, lists
enum PriceTagSize { normal, small }
