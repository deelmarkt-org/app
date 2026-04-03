import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';
import 'package:deelmarkt/widgets/inputs/deel_search_input.dart';

import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_bottom_sheet.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_initial_view.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_results_view.dart';

/// Search screen — B-52.
///
/// Route: `/search?q=` (deep link + bottom nav).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchNotifierProvider.notifier).search(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final placeholder = 'search.placeholder'.tr();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s4,
                Spacing.s3,
                Spacing.s4,
                0,
              ),
              child: Semantics(
                label: placeholder,
                textField: true,
                child: DeelSearchInput(
                  label: placeholder,
                  hint: placeholder,
                  controller: _controller,
                  onDebouncedChanged: (query) {
                    if (query.trim().isEmpty) {
                      ref.invalidate(searchNotifierProvider);
                    } else {
                      ref.read(searchNotifierProvider.notifier).search(query);
                    }
                  },
                  onFilterTap: () => _showFilterSheet(context),
                ),
              ),
            ),
            const SizedBox(height: Spacing.s3),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<SearchState> state) {
    return state.when(
      loading: () => _SearchLoadingView(),
      error:
          (_, _) =>
              ErrorState(onRetry: () => ref.invalidate(searchNotifierProvider)),
      data: (data) {
        if (!data.filter.hasQuery && !data.filter.hasActiveFilters) {
          return SearchInitialView(
            recentSearches: data.recentSearches,
            onRecentTap: _onRecentTap,
            onRemoveRecent:
                (q) => ref
                    .read(searchNotifierProvider.notifier)
                    .removeRecentSearch(q),
            onClearAll:
                () =>
                    ref
                        .read(searchNotifierProvider.notifier)
                        .clearRecentSearches(),
            onCategoryTap: _onCategoryTap,
          );
        }
        return SearchResultsView(
          data: data,
          onListingTap:
              (id) =>
                  context.push(AppRoutes.listingDetail.replaceFirst(':id', id)),
          onFavouriteTap: (id) {
            // TODO: Wire to toggleFavourite when search notifier supports it
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('action.comingSoon'.tr())));
          },
          onLoadMore:
              () => ref.read(searchNotifierProvider.notifier).loadMore(),
          onFilterTap: () => _showFilterSheet(context),
        );
      },
    );
  }

  void _onRecentTap(String query) {
    _controller.text = query;
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  void _onCategoryTap(String categoryId) {
    _controller.text = '';
    ref
        .read(searchNotifierProvider.notifier)
        .updateFilter(SearchFilter(categoryId: categoryId));
  }

  void _showFilterSheet(BuildContext context) {
    final current = ref.read(searchNotifierProvider).valueOrNull;
    if (current == null) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    showFilterBottomSheet(
      context: context,
      currentFilter: current.filter,
      onApply:
          (filter) =>
              ref.read(searchNotifierProvider.notifier).updateFilter(filter),
      reduceMotion: reduceMotion,
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 4;
    if (Breakpoints.isCompact(context)) {
      crossAxisCount = 2;
    } else if (Breakpoints.isMedium(context)) {
      crossAxisCount = 3;
    }

    return Semantics(
      label: 'a11y.loading'.tr(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(Spacing.s4),
            sliver: SliverGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: Spacing.s3,
              crossAxisSpacing: Spacing.s3,
              childAspectRatio: 0.7,
              children: List.generate(6, (_) => const SkeletonListingCard()),
            ),
          ),
        ],
      ),
    );
  }
}
