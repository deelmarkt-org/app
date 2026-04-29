import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_row.dart';

/// Recent activity feed list for the admin dashboard.
///
/// Each row is rendered by [AdminActivityRow] (extracted in P-55), which maps
/// [ActivityItemType] to a Phosphor icon, builds the localised title/subtitle
/// from `admin.activity.<type>.{title,subtitle}` keys with `item.params` as
/// named arguments, and formats a relative timestamp.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminActivityFeed extends StatelessWidget {
  const AdminActivityFeed({required this.items, this.onViewAll, super.key});

  /// Activity items to render, ordered newest-first.
  final List<ActivityItemEntity> items;

  /// Called when the user taps "View All". When null the link is hidden
  /// (WCAG 4.1.2 — interactive elements must have a determinable purpose).
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: Spacing.s3),
          ...items.map((item) => AdminActivityRow(item: item)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'admin.activity.title'.tr(),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: DeelmarktColors.neutral900),
        ),
        if (onViewAll != null)
          Semantics(
            label: 'admin.activity.view_all'.tr(),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.s2,
                  vertical: Spacing.s1,
                ),
                child: Text(
                  'admin.activity.view_all'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: DeelmarktColors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
