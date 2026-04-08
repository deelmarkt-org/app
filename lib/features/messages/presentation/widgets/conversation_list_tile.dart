import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_tile_support.dart';

/// P-35 — Single row in the conversation list.
///
/// Layout (per `docs/screens/06-chat/01-conversation-list.md`):
/// `[64 avatar + online dot]  [name · preview · listing chip]  [badge · thumb]`
///
/// Read/unread rendering: unread rows render the counterpart name bold and
/// the preview in primary orange + bold. Read rows use neutral tones.
class ConversationListTile extends StatelessWidget {
  const ConversationListTile({
    required this.conversation,
    required this.onTap,
    required this.now,
    this.selected = false,
    super.key,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;
  final DateTime now;
  final bool selected;

  bool get _isUnread => conversation.unreadCount > 0;

  /// SECURITY F-09: UI-only placeholder presence flag.
  ///
  /// The hash-of-userId trick is a deterministic cosmetic signal for the mock
  /// preview; it has no confidentiality consequence today because all presence
  /// is fake. It MUST NOT be used by any real presence logic — when the real
  /// presence subsystem ships, this getter is replaced by a `presenceProvider`
  /// lookup and the field must never be derived from `otherUserId` again.
  bool get _isOnline => conversation.otherUserId.hashCode.isEven;

  @override
  Widget build(BuildContext context) {
    final colors = ChatThemeColors.of(context);

    return Semantics(
      button: true,
      label: _semanticLabel(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(Spacing.s5),
            decoration: BoxDecoration(
              color: _rowBg(colors),
              borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                ConversationListTileAvatar(
                  url: conversation.otherUserAvatarUrl,
                  isOnline: _isOnline,
                  colors: colors,
                ),
                const SizedBox(width: Spacing.s4),
                Expanded(child: _buildBody(context, colors)),
                const SizedBox(width: Spacing.s3),
                _buildTrailing(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _rowBg(ChatThemeColors colors) =>
      selected ? colors.selectedRowBg : colors.surface;

  Widget _buildBody(BuildContext context, ChatThemeColors colors) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNameRow(theme, colors),
        const SizedBox(height: Spacing.s1),
        Text(
          conversation.lastMessageType == 'offer'
              ? 'messages.offerPreview'.tr(
                namedArgs: {'amount': conversation.lastMessageText},
              )
              : conversation.lastMessageText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _previewColor(colors),
            fontWeight: _isUnread ? FontWeight.w700 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s2),
        ConversationListTileListingChip(
          title: conversation.listingTitle,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildNameRow(ThemeData theme, ChatThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            conversation.otherUserName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: _isUnread ? FontWeight.w800 : FontWeight.w700,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Spacing.s2),
        Text(
          ChatDateFormatter.relativeRowTimestamp(
            conversation.lastMessageAt,
            now: now,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _timestampColor(colors),
            fontWeight: _isUnread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(ChatThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Parent Semantics already announces the count via messages.unreadA11y
        // — suppress the raw badge text so TalkBack doesn't read it twice.
        if (_isUnread)
          ExcludeSemantics(
            child: ConversationListTileUnreadBadge(
              count: conversation.unreadCount,
              colors: colors,
            ),
          )
        else
          const SizedBox(
            height: ConversationListTileUnreadBadge.minBadgeHeight,
          ),
        const SizedBox(height: Spacing.s2),
        ConversationListTileListingThumb(
          url: conversation.listingImageUrl,
          colors: colors,
        ),
      ],
    );
  }

  Color _previewColor(ChatThemeColors colors) =>
      _isUnread ? colors.primary : colors.textSecondary;

  Color _timestampColor(ChatThemeColors colors) =>
      _isUnread ? colors.primary : colors.textTertiary;

  String _semanticLabel() {
    final preview =
        conversation.lastMessageType == 'offer'
            ? 'messages.offerPreview'.tr(
              namedArgs: {'amount': conversation.lastMessageText},
            )
            : conversation.lastMessageText;
    final parts = <String>[conversation.otherUserName, preview];
    if (_isUnread) {
      parts.add(
        'messages.unreadA11y'.tr(
          namedArgs: {'count': conversation.unreadCount.toString()},
        ),
      );
    }
    return parts.join('. ');
  }
}
