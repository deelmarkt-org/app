import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Shows the search filter bottom sheet.
void showFilterBottomSheet({
  required BuildContext context,
  required SearchFilter currentFilter,
  required ValueChanged<SearchFilter> onApply,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DeelmarktRadius.xl),
      ),
    ),
    builder:
        (_) => _FilterSheet(currentFilter: currentFilter, onApply: onApply),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.currentFilter, required this.onApply});

  final SearchFilter currentFilter;
  final ValueChanged<SearchFilter> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilter _filter;

  static const _maxPriceCents = 500000;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
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
              _buildPriceSection(theme),
              const Divider(height: Spacing.s6),
              _buildConditionSection(theme),
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

  Widget _buildPriceSection(ThemeData theme) {
    final min = (_filter.minPriceCents ?? 0).toDouble();
    final max = (_filter.maxPriceCents ?? _maxPriceCents).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.price'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        RangeSlider(
          values: RangeValues(min, max),
          max: _maxPriceCents.toDouble(),
          divisions: 100,
          labels: RangeLabels(
            Formatters.euroFromCents(min.round()),
            Formatters.euroFromCents(max.round()),
          ),
          onChanged: (values) {
            setState(() {
              _filter = _filter.copyWith(
                minPriceCents:
                    () => values.start > 0 ? values.start.round() : null,
                maxPriceCents:
                    () =>
                        values.end < _maxPriceCents ? values.end.round() : null,
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.euroFromCents(min.round()),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              Formatters.euroFromCents(max.round()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.filter.condition'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        ...ListingCondition.values.map((c) {
          return CheckboxListTile(
            title: Text('condition.${c.name}'.tr()),
            value: _filter.condition == c,
            onChanged: (checked) {
              setState(() {
                _filter = _filter.copyWith(
                  condition: () => checked == true ? c : null,
                );
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
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
            setState(() {
              _filter = _filter.copyWith(sortOrder: value);
            });
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
          child: DeelButton(
            label: 'search.filter.reset'.tr(),
            onPressed: () {
              setState(() {
                _filter = SearchFilter(query: _filter.query);
              });
            },
            variant: DeelButtonVariant.outline,
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: DeelButton(
            label: 'search.filter.apply'.tr(),
            onPressed: () {
              widget.onApply(_filter);
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
