import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// One nav-list row used by [AdminSidebar]: icon + label + selected styling.
///
/// Extracted from `admin_sidebar.dart` (P-55).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminSidebarNavTile extends StatelessWidget {
  const AdminSidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? DeelmarktColors.primarySurface : Colors.transparent;
    final fg = selected ? DeelmarktColors.primary : DeelmarktColors.neutral700;
    final radius = BorderRadius.circular(DeelmarktRadius.sm);

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.s3,
              vertical: Spacing.s2,
            ),
            child: Row(
              children: [
                Icon(icon, size: DeelmarktIconSize.sm, color: fg),
                const SizedBox(width: Spacing.s3),
                Expanded(
                  child: Text(
                    label,
                    style: (selected
                            ? Theme.of(context).textTheme.labelLarge
                            : Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
