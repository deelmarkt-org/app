import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

/// Cascading L1 -> L2 category dropdown pair.
///
/// L1 categories are cached via [topLevelCategoriesProvider].
/// When L1 changes, L2 resets and reloads via [subcategoriesProvider].
class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    required this.categoryL1Id,
    required this.categoryL2Id,
    required this.onL1Changed,
    required this.onL2Changed,
    super.key,
  });

  final String? categoryL1Id;
  final String? categoryL2Id;
  final void Function(String?) onL1Changed;
  final void Function(String?) onL2Changed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l1Async = ref.watch(topLevelCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // L1 category dropdown.
        l1Async.when(
          data:
              (categories) => DropdownButtonFormField<String>(
                initialValue: categoryL1Id,
                decoration: InputDecoration(
                  labelText: 'sell.category'.tr(),
                  hintText: 'sell.categoryL1Hint'.tr(),
                ),
                items:
                    categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                onChanged: (id) {
                  onL1Changed(id);
                  onL2Changed(null);
                },
              ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text('error.generic'.tr()),
        ),

        // L2 subcategory dropdown (visible when L1 is selected).
        if (categoryL1Id != null) ...[
          const SizedBox(height: Spacing.s3),
          _buildL2Dropdown(ref),
        ],
      ],
    );
  }

  Widget _buildL2Dropdown(WidgetRef ref) {
    final l2Async = ref.watch(subcategoriesProvider(categoryL1Id!));

    return l2Async.when(
      data:
          (subcategories) => DropdownButtonFormField<String>(
            initialValue: categoryL2Id,
            decoration: InputDecoration(hintText: 'sell.categoryL2Hint'.tr()),
            items:
                subcategories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
            onChanged: onL2Changed,
          ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text('error.generic'.tr()),
    );
  }
}
