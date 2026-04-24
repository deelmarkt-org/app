import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_providers.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_condition_section.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_distance_section.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_price_section.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Render variant for [FilterPanel] — controls chrome (drag handle, footer)
/// and apply semantics (buffer vs live).
enum FilterPanelVariant {
  /// Bottom-sheet layout: drag handle at top, Reset+Apply footer at bottom.
  /// Mutations buffer locally; [FilterPanel.onApply] fires only when the
  /// "Apply" button is tapped.
  sheet,

  /// Desktop-sidebar layout: no drag handle, no Apply button. Every
  /// mutation calls [FilterPanel.onApply] immediately so the results grid
  /// next to the sidebar can re-fetch live.
  sidebar,
}

/// Shared filter panel consumed by both the mobile bottom sheet and the
/// desktop sidebar on `SearchResultsView`.
///
/// The [variant] controls three behavioural differences — see
/// [FilterPanelVariant] for the contract. Both variants render the same
/// five sections in the same order: price, condition, distance, category,
/// sort.
///
/// Reference: docs/screens/02-home/03-search.md §Responsive —
/// "Expanded: filter sidebar left (permanent), results grid right".
class FilterPanel extends StatefulWidget {
  const FilterPanel({
    required this.filter,
    required this.onApply,
    this.variant = FilterPanelVariant.sheet,
    this.scrollController,
    super.key,
  });

  final SearchFilter filter;

  /// Fired with the current filter. In [FilterPanelVariant.sheet] this is
  /// only called when the user taps the "Apply" button; in
  /// [FilterPanelVariant.sidebar] it is called on every mutation so the
  /// results grid can re-fetch live.
  final ValueChanged<SearchFilter> onApply;

  final FilterPanelVariant variant;

  /// Optional scroll controller wired up by the bottom sheet's
  /// [DraggableScrollableSheet]. The sidebar variant does not use it.
  final ScrollController? scrollController;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

/// Per CLAUDE.md §1.3 this widget uses a local [ValueNotifier] instead of
/// `setState` so the buffered-edit state stays ephemeral and rebuilds are
/// scoped to the [ValueListenableBuilder]. ValueNotifier is an established
/// Flutter pattern in this codebase (see `make_offer_sheet.dart`,
/// `scam_alert.dart`).
class _FilterPanelState extends State<FilterPanel> {
  late final ValueNotifier<SearchFilter> _filter;

  @override
  void initState() {
    super.initState();
    _filter = ValueNotifier<SearchFilter>(widget.filter);
  }

  @override
  void didUpdateWidget(FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sidebar callers own the filter state; sync the mirror when the
    // parent updates. Sheet callers don't change their filter mid-show.
    if (widget.variant == FilterPanelVariant.sidebar &&
        widget.filter != _filter.value) {
      _filter.value = widget.filter;
    }
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  bool get _isSidebar => widget.variant == FilterPanelVariant.sidebar;

  void _updateFilter(SearchFilter updated) {
    _filter.value = updated;
    if (_isSidebar) {
      widget.onApply(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<SearchFilter>(
      valueListenable: _filter,
      builder: (context, filter, _) {
        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          children: [
            if (!_isSidebar) ...[
              const SizedBox(height: Spacing.s2),
              _DragHandle(theme: theme),
              const SizedBox(height: Spacing.s4),
            ] else
              const SizedBox(height: Spacing.s4),
            FilterPriceSection(filter: filter, onChanged: _updateFilter),
            const Divider(height: Spacing.s6),
            FilterConditionSection(filter: filter, onChanged: _updateFilter),
            const Divider(height: Spacing.s6),
            FilterDistanceSection(filter: filter, onChanged: _updateFilter),
            const Divider(height: Spacing.s6),
            _CategorySection(filter: filter, onChanged: _updateFilter),
            const Divider(height: Spacing.s6),
            _SortSection(filter: filter, onChanged: _updateFilter),
            const SizedBox(height: Spacing.s6),
            _ActionsRow(
              variant: widget.variant,
              onReset: () {
                _updateFilter(SearchFilter(query: filter.query));
              },
              onApply: () {
                widget.onApply(filter);
                Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(height: Spacing.s4),
          ],
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(DeelmarktRadius.full),
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.filter, required this.onChanged});

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(topLevelCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.category'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        categoriesAsync.when(
          loading: () => const SizedBox(height: Spacing.s12),
          error:
              (_, _) => TextButton.icon(
                onPressed: () => ref.invalidate(topLevelCategoriesProvider),
                icon: const Icon(Icons.refresh, size: DeelmarktIconSize.xs),
                label: Text('action.retry'.tr()),
              ),
          data:
              (categories) => Wrap(
                spacing: Spacing.s2,
                runSpacing: Spacing.s2,
                children:
                    categories.map((cat) {
                      final isSelected = filter.categoryId == cat.id;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          onChanged(
                            filter.copyWith(
                              categoryId: () => selected ? cat.id : null,
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DeelmarktRadius.xxl,
                          ),
                        ),
                      );
                    }).toList(),
              ),
        ),
      ],
    );
  }
}

class _SortSection extends StatelessWidget {
  const _SortSection({required this.filter, required this.onChanged});

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.sort'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        RadioGroup<SearchSortOrder>(
          groupValue: filter.sortOrder,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(sortOrder: value));
            }
          },
          child: Column(
            children:
                SearchSortOrder.values.map((s) {
                  return RadioListTile<SearchSortOrder>(
                    title: Text('search.sort.${s.name}'.tr()),
                    value: s,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.variant,
    required this.onReset,
    required this.onApply,
  });

  final FilterPanelVariant variant;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final resetButton = Semantics(
      button: true,
      label: 'search.filter.reset'.tr(),
      child: DeelButton(
        label: 'search.filter.reset'.tr(),
        onPressed: onReset,
        variant: DeelButtonVariant.outline,
      ),
    );

    // Sidebar mode applies on every mutation, so no Apply button is needed.
    if (variant == FilterPanelVariant.sidebar) {
      return SizedBox(width: double.infinity, child: resetButton);
    }

    return Row(
      children: [
        Expanded(child: resetButton),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Semantics(
            button: true,
            label: 'search.filter.apply'.tr(),
            child: DeelButton(
              label: 'search.filter.apply'.tr(),
              onPressed: onApply,
            ),
          ),
        ),
      ],
    );
  }
}
