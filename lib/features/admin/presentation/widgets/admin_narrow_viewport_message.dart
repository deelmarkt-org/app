import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Shown in place of the admin shell when the viewport is too narrow
/// (< 768 px) for the two-column sidebar + content layout.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminNarrowViewportMessage extends StatelessWidget {
  const AdminNarrowViewportMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Semantics(
        label: 'admin.narrow_viewport.title'.tr(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  PhosphorIconsRegular.desktopTower,
                  size: DeelmarktIconSize.xl,
                  color: DeelmarktColors.neutral300,
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  'admin.narrow_viewport.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DeelmarktColors.neutral900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.s2),
                Text(
                  'admin.narrow_viewport.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DeelmarktColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
