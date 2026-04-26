import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_filter_chip_bar.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_result_count_text.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_scroll_view.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

/// Compact-viewport (<840 px) layout for search results.
///
/// Sticky header carries the live-region result count + the horizontal
/// chip bar; tapping any chip opens the filter bottom sheet via
/// [onFilterTap]. Empty results render a single [EmptyState] whose
/// retry CTA opens the same bottom sheet so the user can broaden their
/// criteria without leaving the view.
class SearchResultsCompactView extends StatelessWidget {
  const SearchResultsCompactView({
    required this.data,
    required this.onListingTap,
    required this.onFavouriteTap,
    required this.onLoadMore,
    required this.onFilterTap,
    super.key,
  });

  final SearchState data;
  final ValueChanged<String> onListingTap;
  final ValueChanged<String> onFavouriteTap;
  final VoidCallback onLoadMore;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    if (data.listings.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.search,
        onAction: onFilterTap,
      );
    }
    return SearchResultsScrollView(
      headerSliver: SliverToBoxAdapter(child: _buildHeader(context)),
      listings: data.listings,
      isLoadingMore: data.isLoadingMore,
      onListingTap: onListingTap,
      onFavouriteTap: onFavouriteTap,
      onLoadMore: onLoadMore,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchResultCountText(data: data),
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
}
