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
    final columns = Breakpoints.gridColumnsForWidth(context);
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: Spacing.s3,
          crossAxisSpacing: Spacing.s3,
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
