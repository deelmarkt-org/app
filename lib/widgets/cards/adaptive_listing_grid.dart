import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

/// Sliver grid for listing cards that adapts its column count to the
/// viewport (2 / 3 / 4 / 5 per [Breakpoints.gridColumnsForWidth]) and uses
/// the canonical [DeelCardTokens.gridChildAspectRatio] + standard spacing.
///
/// Consumers: home nearby grid, search results, favourites, category detail,
/// profile listings.
///
/// When the grid is placed inside a layout that occupies only part of the
/// viewport (e.g. the results pane next to a filter sidebar), pass
/// [crossAxisCountOverride] so the column count reflects the container width
/// rather than the full `MediaQuery` width. Use
/// [Breakpoints.gridColumnsForWidthValue] to compute the override.
///
/// Reference: docs/design-system/tokens.md §Breakpoints, components.md §Listing Card.
class AdaptiveListingGrid extends StatelessWidget {
  const AdaptiveListingGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.s4),
    this.crossAxisCountOverride,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  /// Explicit column count — overrides the viewport-based default.
  ///
  /// Set this when the grid does not span the full viewport width.
  /// Compute via [Breakpoints.gridColumnsForWidthValue].
  final int? crossAxisCountOverride;

  @override
  Widget build(BuildContext context) {
    final columns =
        crossAxisCountOverride ?? Breakpoints.gridColumnsForWidth(context);
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: Spacing.listingCardGap,
          crossAxisSpacing: Spacing.listingCardGap,
          childAspectRatio: DeelCardTokens.gridChildAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      ),
    );
  }
}
