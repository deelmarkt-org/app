import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_result_count_text.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_scroll_view.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Expanded-viewport (≥840 px) layout for search results.
///
/// Fixed [Breakpoints.filterSidebarWidth] left sidebar renders the
/// shared [FilterPanel] in sidebar variant (live-apply via
/// [onFilterApply]); the right pane renders the result-count line +
/// adaptive grid via [SearchResultsScrollView]. Empty results swap the
/// pane for [EmptyState]; the sidebar stays so the user can mutate the
/// filter without scrolling.
class SearchResultsExpandedView extends StatelessWidget {
  const SearchResultsExpandedView({
    required this.data,
    required this.onListingTap,
    required this.onFavouriteTap,
    required this.onLoadMore,
    required this.onFilterApply,
    super.key,
  });

  final SearchState data;
  final ValueChanged<String> onListingTap;
  final ValueChanged<String> onFavouriteTap;
  final VoidCallback onLoadMore;
  final ValueChanged<SearchFilter> onFilterApply;

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: _buildResultsPane(context)),
        ],
      ),
    );
  }

  Widget _buildResultsPane(BuildContext context) {
    if (data.listings.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.search,
        // Reset all filter criteria (keep the search query) so the user can
        // broaden their results without leaving the expanded layout.
        onAction: () => onFilterApply(SearchFilter(query: data.filter.query)),
      );
    }
    // The grid is container-aware via SliverLayoutBuilder, so the column
    // count is derived from the results pane's actual `crossAxisExtent`
    // (viewport − sidebar − 1-px divider) rather than the full viewport
    // via MediaQuery (#193 PR D / #210 review C1).
    return SearchResultsScrollView(
      headerSliver: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s4,
            Spacing.s3,
            Spacing.s4,
            Spacing.s2,
          ),
          child: SearchResultCountText(data: data),
        ),
      ),
      listings: data.listings,
      isLoadingMore: data.isLoadingMore,
      hasMore: data.hasMore,
      onListingTap: onListingTap,
      onFavouriteTap: onFavouriteTap,
      onLoadMore: onLoadMore,
    );
  }
}
