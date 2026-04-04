import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// P-35/P-36 — Right-pane placeholder shown in expanded master-detail
/// layout before the user selects a conversation.
class NoThreadSelected extends StatelessWidget {
  const NoThreadSelected({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final textColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.chatsCircle(PhosphorIconsStyle.duotone),
              size: 72,
              color: iconColor,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'messages.noThreadSelected'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
