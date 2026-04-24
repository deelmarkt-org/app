import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_filter_chip_bar.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/escrow_aware_listing_card.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

// Canonical sidebar width lives in Breakpoints.filterSidebarWidth (240 dp).
// The local alias is kept so call sites inside this file stay readable.

/// Search results with filter controls + result count + infinite scroll.
///
/// - **Compact (<840)**: sticky header with result count + horizontal
///   `_FilterChipBar`; tapping any chip opens the filter bottom sheet via
///   [onFilterTap]. 2-col grid below the header.
/// - **Expanded (≥840)**: fixed 240-px left sidebar rendering the shared
///   [FilterPanel] in sidebar variant (live-apply via [onFilterApply]),
///   right pane renders the result count + grid. Horizontal chip bar is
///   replaced by the sidebar; bottom sheet is not used on expanded.
///
/// Reference: docs/screens/02-home/03-search.md §Responsive,
/// `docs/screens/02-home/designs/search_desktop_results_sidebar`.
class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    required this.data,
    required this.onListingTap,
    required this.onFavouriteTap,
    required this.onLoadMore,
    required this.onFilterTap,
    required this.onFilterApply,
    super.key,
  });

  final SearchState data;
  final ValueChanged<String> onListingTap;
  final ValueChanged<String> onFavouriteTap;
  final VoidCallback onLoadMore;

  /// Compact callback — opens the filter bottom sheet.
  final VoidCallback onFilterTap;

  /// Expanded callback — applied live by the sidebar panel on each
  /// mutation. Parent wires this to `searchNotifier.updateFilter`.
  final ValueChanged<SearchFilter> onFilterApply;

  @override
  Widget build(BuildContext context) {
    final isExpanded = Breakpoints.isExpanded(context);
    if (isExpanded) {
      return _buildExpanded(context);
    }
    return _buildCompact(context);
  }

  Widget _buildExpanded(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody.wide(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: Breakpoints.filterSidebarWidth,
            child: FilterPanel(
              filter: data.filter,
              onApply: onFilterApply,
              variant: FilterPanelVariant.sidebar,
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          Expanded(child: _buildExpandedResultsPane(context)),
        ],
      ),
    );
  }

  Widget _buildExpandedResultsPane(BuildContext context) {
    if (data.listings.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.search,
        // Reset all filter criteria (keep the search query) so the user can
        // broaden their results without leaving the expanded layout.
        onAction: () => onFilterApply(SearchFilter(query: data.filter.query)),
      );
    }
    // The results pane occupies (viewport − sidebar − 1 px divider) dp.
    // Pass the container width to the grid so it picks the right column count
    // rather than reading the full viewport via MediaQuery (#210 review C1).
    final paneWidth =
        MediaQuery.sizeOf(context).width - Breakpoints.filterSidebarWidth - 1;
    final paneColumns = Breakpoints.gridColumnsForWidthValue(paneWidth);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildResultCount(context)),
          _buildGrid(context, crossAxisCountOverride: paneColumns),
          if (data.isLoadingMore) _loadMoreSpinner(),
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    if (data.listings.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.search,
        onAction: onFilterTap,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCompactHeader(context)),
          _buildGrid(context),
          if (data.isLoadingMore) _loadMoreSpinner(),
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
        ],
      ),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.extentAfter < 200) {
      onLoadMore();
    }
    return false;
  }

  Widget _buildCompactHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultCountText(data: data, isDark: isDark, theme: theme),
          const SizedBox(height: Spacing.s2),
          SearchFilterChipBar(
            filter: data.filter,
            onTap: onFilterTap,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.s3),
        ],
      ),
    );
  }

  Widget _buildResultCount(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s4,
        Spacing.s3,
        Spacing.s4,
        Spacing.s2,
      ),
      child: _ResultCountText(data: data, isDark: isDark, theme: theme),
    );
  }

  Widget _buildGrid(BuildContext context, {int? crossAxisCountOverride}) {
    return AdaptiveListingGrid(
      itemCount: data.listings.length,
      crossAxisCountOverride: crossAxisCountOverride,
      itemBuilder: (context, index) {
        final listing = data.listings[index];
        return EscrowAwareListingCard(
          listing: listing,
          onTap: () => onListingTap(listing.id),
          onFavouriteTap: () => onFavouriteTap(listing.id),
        );
      },
    );
  }

  Widget _loadMoreSpinner() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(Spacing.s4),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ResultCountText extends StatelessWidget {
  const _ResultCountText({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  final SearchState data;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        'search.resultsFor'.tr(
          namedArgs: {'query': data.filter.query, 'count': '${data.total}'},
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              isDark
                  ? DeelmarktColors.darkOnSurfaceSecondary
                  : DeelmarktColors.neutral500,
        ),
      ),
    );
  }
}
