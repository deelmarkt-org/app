import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

/// P-36 — Sticky app bar for the chat thread screen.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md` §App bar.
/// Back arrow visibility is controlled by the caller so the expanded
/// master-detail layout can omit it in the right pane.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({
    required this.conversation,
    required this.showBackButton,
    this.onOptionsPressed,
    super.key,
  });

  final ConversationEntity conversation;
  final bool showBackButton;
  final VoidCallback? onOptionsPressed;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  /// SECURITY F-09: UI-only placeholder — see conversation_list_tile.dart for
  /// the full rationale. Must not be used by any real presence logic.
  bool get _isOnline => conversation.otherUserId.hashCode.isEven;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white;
    final nameColor =
        isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900;
    final statusColor =
        _isOnline
            ? (isDark ? DeelmarktColors.darkSuccess : DeelmarktColors.success)
            : (isDark
                ? DeelmarktColors.darkOnSurfaceSecondary
                : DeelmarktColors.neutral500);

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isDark
                        ? DeelmarktColors.darkBorder
                        : DeelmarktColors.neutral200,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'chat.backA11y'.tr(),
                  onPressed: () => Navigator.of(context).maybePop(),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                )
              else
                const SizedBox(width: Spacing.s2),
              const SizedBox(width: Spacing.s2),
              _SmallAvatar(
                url: conversation.otherUserAvatarUrl,
                isOnline: _isOnline,
                isDark: isDark,
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.otherUserName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isOnline ? 'chat.online'.tr() : 'chat.lastSeen'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'chat.optionsMenuA11y'.tr(),
                onPressed: onOptionsPressed,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({
    required this.url,
    required this.isOnline,
    required this.isDark,
  });

  final String? url;
  final bool isOnline;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral100;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              image:
                  url != null && url!.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(url!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                url == null || url!.isEmpty
                    ? Icon(
                      Icons.person,
                      size: 20,
                      color:
                          isDark
                              ? DeelmarktColors.darkOnSurfaceSecondary
                              : DeelmarktColors.neutral500,
                    )
                    : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    isOnline
                        ? (isDark
                            ? DeelmarktColors.darkSuccess
                            : DeelmarktColors.success)
                        : DeelmarktColors.neutral300,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isDark
                          ? DeelmarktColors.darkSurface
                          : DeelmarktColors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
