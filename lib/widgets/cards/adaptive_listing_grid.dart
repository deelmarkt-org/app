import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

/// Sliver grid for listing cards that adapts its column count to the
/// **actual width of the container it renders inside** (via
/// [SliverLayoutBuilder] + [Breakpoints.gridColumnsForContainerWidth]) and
/// uses the canonical [DeelCardTokens.gridChildAspectRatio] + standard
/// spacing.
///
/// Container-aware is critical: this grid renders alongside fixed sidebars
/// (search filter panel), inside width-capped scroll views
/// (`ResponsiveBody.wide`), and as a full-viewport grid on mobile. A
/// viewport-based column count would produce 5 cols inside the ~1159-px
/// search results pane (1400-px viewport, minus 240-px sidebar, minus
/// 1-px divider) — not enough horizontal room for `DeelCard` content, and
/// the card would overflow by ~16 px vertically. Reading
/// `crossAxisExtent` from the sliver's own constraints keeps the column
/// count proportional to the space the grid actually occupies.
///
/// Full-width surfaces (home / favourites / category-detail without a
/// sidebar) see identical column counts to the pre-migration behaviour
/// because `crossAxisExtent` equals the viewport width there.
///
/// Consumers: home nearby grid, search results, favourites, category detail,
/// profile listings.
///
/// Reference: docs/design-system/tokens.md §Breakpoints, components.md §Listing Card.
class AdaptiveListingGrid extends StatelessWidget {
  const AdaptiveListingGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.s4),
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.gridColumnsForContainerWidth(
          constraints.crossAxisExtent,
        );
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
      },
    );
  }
}
