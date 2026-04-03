import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

/// Cascading L1 → L2 category dropdown pair.
///
/// L1 categories are cached via [topLevelCategoriesProvider].
/// When L1 changes, L2 resets and reloads via repository.
class CategorySelector extends ConsumerStatefulWidget {
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
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  List<CategoryEntity> _subcategories = const [];
  bool _loadingL2 = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryL1Id != null) {
      _loadSubcategories(widget.categoryL1Id!);
    }
  }

  Future<void> _loadSubcategories(String parentId) async {
    setState(() => _loadingL2 = true);
    final repo = ref.read(categoryRepositoryProvider);
    final subs = await repo.getSubcategories(parentId);
    if (mounted) {
      setState(() {
        _subcategories = subs;
        _loadingL2 = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l1Async = ref.watch(topLevelCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // L1 category dropdown.
        l1Async.when(
          data:
              (categories) => DropdownButtonFormField<String>(
                initialValue: widget.categoryL1Id,
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
                  widget.onL1Changed(id);
                  widget.onL2Changed(null);
                  if (id != null) {
                    _loadSubcategories(id);
                  } else {
                    setState(() => _subcategories = const []);
                  }
                },
              ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text('error.generic'.tr()),
        ),

        // L2 subcategory dropdown (visible when L1 is selected).
        if (widget.categoryL1Id != null) ...[
          const SizedBox(height: Spacing.s3),
          if (_loadingL2)
            const LinearProgressIndicator()
          else
            DropdownButtonFormField<String>(
              initialValue: widget.categoryL2Id,
              decoration: InputDecoration(hintText: 'sell.categoryL2Hint'.tr()),
              items:
                  _subcategories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
              onChanged: widget.onL2Changed,
            ),
        ],
      ],
    );
  }
}
