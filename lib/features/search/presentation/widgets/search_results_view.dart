import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/presentation/widgets/listing_card.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

/// Search results grid with filter chips, result count, and infinite scroll.
class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          onLoadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          _buildGrid(context),
          if (data.isLoadingMore)
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filterCount = data.filter.activeFilterCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              'search.resultsFor'.tr(
                namedArgs: {
                  'query': data.filter.query,
                  'count': '${data.total}',
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurfaceSecondary
                        : DeelmarktColors.neutral500,
              ),
            ),
          ),
          const SizedBox(height: Spacing.s2),
          ActionChip(
            avatar: Icon(
              PhosphorIcons.funnelSimple(),
              size: DeelmarktIconSize.sm,
            ),
            label: Text(
              filterCount > 0
                  ? '${'search.filter.filters'.tr()} ($filterCount)'
                  : 'search.filter.filters'.tr(),
            ),
            onPressed: onFilterTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
              side: BorderSide(
                color:
                    filterCount > 0
                        ? (isDark
                            ? DeelmarktColors.darkPrimary
                            : DeelmarktColors.primary)
                        : theme.colorScheme.outlineVariant,
              ),
            ),
            backgroundColor:
                filterCount > 0
                    ? (isDark
                        ? DeelmarktColors.darkPrimary.withValues(alpha: 0.12)
                        : DeelmarktColors.primarySurface)
                    : null,
          ),
          const SizedBox(height: Spacing.s3),
        ],
      ),
    );
  }

  SliverPadding _buildGrid(BuildContext context) {
    int crossAxisCount = 4;
    if (Breakpoints.isCompact(context)) {
      crossAxisCount = 2;
    } else if (Breakpoints.isMedium(context)) {
      crossAxisCount = 3;
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      sliver: SliverGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Spacing.s3,
        crossAxisSpacing: Spacing.s3,
        childAspectRatio: 0.7,
        children:
            data.listings.map((listing) {
              return ListingCard(
                listing: listing,
                onTap: () => onListingTap(listing.id),
                onFavouriteTap: () => onFavouriteTap(listing.id),
              );
            }).toList(),
      ),
    );
  }
}
