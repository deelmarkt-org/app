import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';

part 'search_initial_view.g.dart';

/// Fetches top-level categories via Riverpod — avoids raw FutureBuilder.
@riverpod
Future<List<CategoryEntity>> topLevelCategories(Ref ref) {
  return ref.watch(categoryRepositoryProvider).getTopLevel();
}

/// Initial search view — recent searches + popular categories.
class SearchInitialView extends ConsumerWidget {
  const SearchInitialView({
    required this.recentSearches,
    required this.onRecentTap,
    required this.onRemoveRecent,
    required this.onClearAll,
    required this.onCategoryTap,
    super.key,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearAll;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(topLevelCategoriesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      children: [
        if (recentSearches.isNotEmpty) ...[
          _SectionHeader(
            title: 'search.recentSearches'.tr(),
            action: Semantics(
              button: true,
              label: 'search.clearAll'.tr(),
              child: TextButton(
                onPressed: onClearAll,
                child: Text('search.clearAll'.tr()),
              ),
            ),
          ),
          ...recentSearches.map(
            (q) => Semantics(
              button: true,
              label: q,
              child: ListTile(
                leading: Icon(
                  PhosphorIcons.clockCounterClockwise(),
                  size: DeelmarktIconSize.sm,
                ),
                title: Text(q),
                trailing: Semantics(
                  button: true,
                  label: 'action.delete'.tr(),
                  child: IconButton(
                    icon: Icon(PhosphorIcons.x(), size: DeelmarktIconSize.sm),
                    onPressed: () => onRemoveRecent(q),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
                onTap: () => onRecentTap(q),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: Spacing.s4),
        ],
        _SectionHeader(title: 'search.popularCategories'.tr()),
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
                      return Semantics(
                        button: true,
                        label: cat.name,
                        child: ActionChip(
                          label: Text(cat.name),
                          onPressed: () => onCategoryTap(cat.id),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DeelmarktRadius.xxl,
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}
