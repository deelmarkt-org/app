import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Placeholder Activity Trends card rendered next to [AdminEmptyHeroCard]
/// in the empty-state dashboard layout. Real chart wiring is part of a
/// follow-up admin analytics task.
///
/// Extracted from `admin_empty_state.dart` (P-55).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminActivityTrendsCard extends StatelessWidget {
  const AdminActivityTrendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.empty.trends_title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: DeelmarktColors.neutral900),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            'admin.empty.trends_empty'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral300),
          ),
        ],
      ),
    );
  }
}
