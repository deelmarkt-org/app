import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

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
                _Avatar(
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
          conversation.lastMessageText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _previewColor(colors),
            fontWeight: _isUnread ? FontWeight.w700 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s2),
        _ListingChip(title: conversation.listingTitle, colors: colors),
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
          ExcludeSemantics(child: _UnreadBadge(count: conversation.unreadCount))
        else
          const SizedBox(height: 20),
        const SizedBox(height: Spacing.s2),
        _ListingThumb(url: conversation.listingImageUrl, colors: colors),
      ],
    );
  }

  Color _previewColor(ChatThemeColors colors) =>
      _isUnread ? colors.primary : colors.textSecondary;

  Color _timestampColor(ChatThemeColors colors) =>
      _isUnread ? colors.primary : colors.textTertiary;

  String _semanticLabel() {
    final parts = <String>[
      conversation.otherUserName,
      conversation.lastMessageText,
    ];
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

class _Avatar extends StatelessWidget {
  const _Avatar({
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
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBase(),
          Positioned(right: 2, bottom: 2, child: _buildPresenceDot()),
        ],
      ),
    );
  }

  Widget _buildBase() {
    return Container(
      width: 64,
      height: 64,
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
              : Icon(Icons.person, size: 32, color: colors.textTertiary),
    );
  }

  Widget _buildPresenceDot() {
    final dotColor = isOnline ? colors.success : DeelmarktColors.neutral300;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
    );
  }
}

class _ListingChip extends StatelessWidget {
  const _ListingChip({required this.title, required this.colors});

  final String title;
  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ListingThumb extends StatelessWidget {
  const _ListingThumb({required this.url, required this.colors});

  final String? url;
  final ChatThemeColors colors;

  bool get _hasImage => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        image:
            _hasImage
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
        border: Border.all(color: colors.border),
      ),
      child:
          _hasImage
              ? null
              : Icon(
                Icons.image_outlined,
                size: 20,
                color: colors.textTertiary,
              ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: DeelmarktColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: DeelmarktColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
