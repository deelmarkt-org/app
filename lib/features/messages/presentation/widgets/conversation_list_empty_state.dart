import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

/// P-35 — Empty state for the conversation list.
///
/// Reference: `docs/screens/06-chat/designs/messages_empty_state`.
class ConversationListEmptyState extends StatelessWidget {
  const ConversationListEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ChatThemeColors.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChatIcon(colors: colors),
              const SizedBox(height: Spacing.s6),
              Text(
                'messages.noConversations'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s2),
              Text(
                'messages.startConversation'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s6),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.explore_outlined),
                label: Text('messages.emptyAction'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: DeelmarktColors.primary,
                  foregroundColor: DeelmarktColors.white,
                  minimumSize: const Size(220, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({required this.colors});
  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        shape: BoxShape.circle,
      ),
      child: Icon(
        PhosphorIcons.chatCircleText(PhosphorIconsStyle.duotone),
        size: DeelmarktIconSize.xl,
        color: colors.textTertiary,
      ),
    );
  }
}
