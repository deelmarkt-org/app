import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: _isUnread ? FontWeight.w800 : FontWeight.w700,
      color:
          isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900,
    );
    final previewColor =
        _isUnread
            ? (isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary)
            : (isDark
                ? DeelmarktColors.darkOnSurfaceSecondary
                : DeelmarktColors.neutral700);
    final previewStyle = theme.textTheme.bodyMedium?.copyWith(
      color: previewColor,
      fontWeight: _isUnread ? FontWeight.w700 : FontWeight.w400,
    );

    final rowBg =
        selected
            ? (isDark
                ? DeelmarktColors.darkSurfaceElevated
                : DeelmarktColors.primarySurface)
            : (isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white);
    final rowBorder =
        isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200;

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
              color: rowBg,
              borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
              border: Border.all(color: rowBorder),
            ),
            child: Row(
              children: [
                _Avatar(
                  url: conversation.otherUserAvatarUrl,
                  isOnline: _isOnline,
                  isDark: isDark,
                ),
                const SizedBox(width: Spacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.otherUserName,
                              style: nameStyle,
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
                              color:
                                  _isUnread
                                      ? (isDark
                                          ? DeelmarktColors.darkPrimary
                                          : DeelmarktColors.primary)
                                      : (isDark
                                          ? DeelmarktColors
                                              .darkOnSurfaceSecondary
                                          : DeelmarktColors.neutral500),
                              fontWeight:
                                  _isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s1),
                      Text(
                        conversation.lastMessageText,
                        style: previewStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacing.s2),
                      _ListingChip(
                        title: conversation.listingTitle,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.s3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isUnread)
                      // Parent Semantics already announces the count via
                      // messages.unreadA11y — suppress the raw badge text
                      // so TalkBack doesn't read it twice (review M#6).
                      ExcludeSemantics(
                        child: _UnreadBadge(count: conversation.unreadCount),
                      )
                    else
                      const SizedBox(height: 20),
                    const SizedBox(height: Spacing.s2),
                    _ListingThumb(
                      url: conversation.listingImageUrl,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
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
                      size: 32,
                      color:
                          isDark
                              ? DeelmarktColors.darkOnSurfaceSecondary
                              : DeelmarktColors.neutral500,
                    )
                    : null,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
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

class _ListingChip extends StatelessWidget {
  const _ListingChip({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral100;
    final fg =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ListingThumb extends StatelessWidget {
  const _ListingThumb({required this.url, required this.isDark});

  final String? url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral100;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        image:
            url != null && url!.isNotEmpty
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
        border: Border.all(
          color:
              isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200,
        ),
      ),
      child:
          url == null || url!.isEmpty
              ? Icon(
                Icons.image_outlined,
                size: 20,
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurfaceSecondary
                        : DeelmarktColors.neutral500,
              )
              : null,
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
