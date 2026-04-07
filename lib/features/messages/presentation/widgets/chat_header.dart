import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

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
    final colors = ChatThemeColors.of(context);

    return Material(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              _buildLeading(context),
              const SizedBox(width: Spacing.s2),
              _SmallAvatar(
                url: conversation.otherUserAvatarUrl,
                isOnline: _isOnline,
                colors: colors,
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(child: _buildTitleBlock(theme, colors)),
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

  Widget _buildLeading(BuildContext context) {
    if (!showBackButton) return const SizedBox(width: Spacing.s2);
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'chat.backA11y'.tr(),
      onPressed: () => Navigator.of(context).maybePop(),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  Widget _buildTitleBlock(ThemeData theme, ChatThemeColors colors) {
    final statusColor = _isOnline ? colors.success : colors.textTertiary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conversation.otherUserName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _isOnline ? 'chat.online'.tr() : 'chat.lastSeen'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
        ),
      ],
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({
    required this.url,
    required this.isOnline,
    required this.colors,
  });

  final String? url;
  final bool isOnline;
  final ChatThemeColors colors;

  bool get _hasImage => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBase(),
          Positioned(right: 0, bottom: 0, child: _buildDot()),
        ],
      ),
    );
  }

  Widget _buildBase() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        shape: BoxShape.circle,
        image:
            _hasImage
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
      ),
      child:
          _hasImage
              ? null
              : Icon(Icons.person, size: 20, color: colors.textTertiary),
    );
  }

  Widget _buildDot() {
    final dotColor = isOnline ? colors.success : DeelmarktColors.neutral300;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
    );
  }
}
