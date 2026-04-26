import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_compact_view.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_expanded_view.dart';

/// Search results with filter controls + result count + infinite scroll.
///
/// Selects the layout by viewport class:
///
/// - **Compact (<840)**: sticky header with result count + horizontal
///   chip bar; tapping any chip opens the filter bottom sheet via
///   [onFilterTap]. 2-col grid below the header. See
///   [SearchResultsCompactView].
/// - **Expanded (≥840)**: fixed 240-px left sidebar rendering the shared
///   [FilterPanel] in sidebar variant (live-apply via [onFilterApply]),
///   right pane renders the result count + grid. See
///   [SearchResultsExpandedView].
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
    if (Breakpoints.isExpanded(context)) {
      return SearchResultsExpandedView(
        data: data,
        onListingTap: onListingTap,
        onFavouriteTap: onFavouriteTap,
        onLoadMore: onLoadMore,
        onFilterApply: onFilterApply,
      );
    }
    return SearchResultsCompactView(
      data: data,
      onListingTap: onListingTap,
      onFavouriteTap: onFavouriteTap,
      onLoadMore: onLoadMore,
      onFilterTap: onFilterTap,
    );
  }
}
