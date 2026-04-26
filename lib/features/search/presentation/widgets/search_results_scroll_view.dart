import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/escrow_aware_listing_card.dart';

/// Shared scroll view used by both the compact and expanded search-result
/// layouts.
///
/// Owns the infinite-scroll listener (fires [onLoadMore] when the user
/// is within 200 px of the bottom **and** there is more data to load),
/// the [AdaptiveListingGrid] of [EscrowAwareListingCard]s, the optional
/// load-more spinner, and the trailing bottom padding. Callers supply a
/// single [headerSliver] that renders above the grid — compact passes
/// the chip-bar header, expanded passes the result-count line.
///
/// The `searchNotifier.loadMore()` already short-circuits redundant
/// calls, but the widget-level guard (`!isLoadingMore && hasMore`)
/// keeps the round-trip out of the hot path so a user fling-scrolling
/// past the threshold doesn't enqueue dozens of no-op notifier reads.
class SearchResultsScrollView extends StatelessWidget {
  const SearchResultsScrollView({
    required this.headerSliver,
    required this.listings,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onListingTap,
    required this.onFavouriteTap,
    required this.onLoadMore,
    super.key,
  });

  final Widget headerSliver;
  final List<ListingEntity> listings;
  final bool isLoadingMore;

  /// `true` when the backend reports more pages are available. When
  /// `false`, the scroll listener stops pinging [onLoadMore] regardless
  /// of how close the user is to the bottom.
  final bool hasMore;

  final ValueChanged<String> onListingTap;
  final ValueChanged<String> onFavouriteTap;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          headerSliver,
          AdaptiveListingGrid(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return EscrowAwareListingCard(
                listing: listing,
                onTap: () => onListingTap(listing.id),
                onFavouriteTap: () => onFavouriteTap(listing.id),
              );
            },
          ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Spacing.s4),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
        ],
      ),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        !isLoadingMore &&
        hasMore &&
        notification.metrics.extentAfter < 200) {
      onLoadMore();
    }
    return false;
  }
}
