import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/cards/listing_deel_card.dart';

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
          _FilterChipBar(
            filter: data.filter,
            onTap: onFilterTap,
            isDark: isDark,
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
        childAspectRatio: DeelCardTokens.gridChildAspectRatio,
        children:
            data.listings.map((listing) {
              return listingDeelCard(
                listing,
                onTap: () => onListingTap(listing.id),
                onFavouriteTap: () => onFavouriteTap(listing.id),
              );
            }).toList(),
      ),
    );
  }
}

/// Horizontal scrollable row of individual filter chips per spec.
class _FilterChipBar extends StatelessWidget {
  const _FilterChipBar({
    required this.filter,
    required this.onTap,
    required this.isDark,
  });

  final SearchFilter filter;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            context,
            label: 'search.filter.price'.tr(),
            isActive:
                filter.minPriceCents != null || filter.maxPriceCents != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.condition'.tr(),
            isActive: filter.condition != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.distance'.tr(),
            isActive: filter.maxDistanceKm != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.category'.tr(),
            isActive: filter.categoryId != null,
          ),
          const SizedBox(width: Spacing.s2),
          _chip(
            context,
            label: 'search.filter.sort'.tr(),
            isActive: filter.sortOrder != SearchSortOrder.relevance,
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeColor =
        isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary;
    final activeBg =
        isDark
            ? DeelmarktColors.darkPrimary.withValues(alpha: 0.12)
            : DeelmarktColors.primarySurface;

    return Semantics(
      button: true,
      label: label,
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
          side: BorderSide(
            color: isActive ? activeColor : theme.colorScheme.outlineVariant,
          ),
        ),
        backgroundColor: isActive ? activeBg : null,
      ),
    );
  }
}
