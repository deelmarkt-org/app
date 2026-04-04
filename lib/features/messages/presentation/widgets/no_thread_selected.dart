import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

/// P-35/P-36 — Right-pane placeholder shown in expanded master-detail
/// layout before the user selects a conversation.
class NoThreadSelected extends StatelessWidget {
  const NoThreadSelected({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ChatThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.chatsCircle(PhosphorIconsStyle.duotone),
              size: 72,
              color: colors.textTertiary,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'messages.noThreadSelected'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
