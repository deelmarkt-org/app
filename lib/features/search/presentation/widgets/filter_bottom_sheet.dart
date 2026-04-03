import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_initial_view.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_condition_section.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_distance_section.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_price_section.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Shows the search filter bottom sheet.
void showFilterBottomSheet({
  required BuildContext context,
  required SearchFilter currentFilter,
  required ValueChanged<SearchFilter> onApply,
  bool reduceMotion = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DeelmarktRadius.xl),
      ),
    ),
    transitionAnimationController:
        reduceMotion
            ? AnimationController(
              vsync: Navigator.of(context),
              duration: Duration.zero,
            )
            : null,
    builder:
        (_) => _FilterSheet(currentFilter: currentFilter, onApply: onApply),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.currentFilter, required this.onApply});

  final SearchFilter currentFilter;
  final ValueChanged<SearchFilter> onApply;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  void _updateFilter(SearchFilter updated) {
    setState(() => _filter = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: Spacing.s2),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(DeelmarktRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.s4),
              FilterPriceSection(filter: _filter, onChanged: _updateFilter),
              const Divider(height: Spacing.s6),
              FilterConditionSection(filter: _filter, onChanged: _updateFilter),
              const Divider(height: Spacing.s6),
              FilterDistanceSection(filter: _filter, onChanged: _updateFilter),
              const Divider(height: Spacing.s6),
              _buildCategorySection(theme),
              const Divider(height: Spacing.s6),
              _buildSortSection(theme),
              const SizedBox(height: Spacing.s6),
              _buildActions(),
              const SizedBox(height: Spacing.s4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
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
          loading: () => const SizedBox(height: 48),
          error: (_, _) => const SizedBox.shrink(),
          data:
              (categories) => Wrap(
                spacing: Spacing.s2,
                runSpacing: Spacing.s2,
                children:
                    categories.map((cat) {
                      final isSelected = _filter.categoryId == cat.id;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          _updateFilter(
                            _filter.copyWith(
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

  Widget _buildSortSection(ThemeData theme) {
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
          groupValue: _filter.sortOrder,
          onChanged: (value) {
            _updateFilter(_filter.copyWith(sortOrder: value));
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

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'search.filter.reset'.tr(),
            child: DeelButton(
              label: 'search.filter.reset'.tr(),
              onPressed: () {
                _updateFilter(SearchFilter(query: _filter.query));
              },
              variant: DeelButtonVariant.outline,
            ),
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Semantics(
            button: true,
            label: 'search.filter.apply'.tr(),
            child: DeelButton(
              label: 'search.filter.apply'.tr(),
              onPressed: () {
                widget.onApply(_filter);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ],
    );
  }
}
