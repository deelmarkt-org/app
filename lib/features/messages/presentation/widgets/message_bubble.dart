import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// P-36 — A single text message bubble in the chat thread.
///
/// Layout follows `docs/screens/06-chat/02-chat-thread.md`:
/// self bubbles are right-aligned with `primarySurface` bg; other bubbles are
/// left-aligned with `neutral100` bg. Bubbles max-width at 75% of the viewport
/// width, which is a de-facto chat convention.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isSelf,
    this.showTimestamp = true,
    this.showReadReceipt = false,
    super.key,
  });

  final MessageEntity message;
  final bool isSelf;
  final bool showTimestamp;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = width * 0.75;

    final bubbleColor =
        isSelf
            ? (isDark
                ? DeelmarktColors.darkChatSelfBubble
                : DeelmarktColors.primarySurface)
            : (isDark
                ? DeelmarktColors.darkChatOtherBubble
                : DeelmarktColors.neutral100);
    final textColor =
        isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(DeelmarktRadius.xl),
      topRight: const Radius.circular(DeelmarktRadius.xl),
      bottomLeft: Radius.circular(
        isSelf ? DeelmarktRadius.xl : DeelmarktRadius.xs,
      ),
      bottomRight: Radius.circular(
        isSelf ? DeelmarktRadius.xs : DeelmarktRadius.xl,
      ),
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: borderRadius),
      child: Text(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
    );

    return Semantics(
      label:
          isSelf
              ? 'chat.selfBubbleA11y'.tr(namedArgs: {'text': message.text})
              : 'chat.otherBubbleA11y'.tr(namedArgs: {'text': message.text}),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s4,
          vertical: Spacing.s1,
        ),
        child: Column(
          crossAxisAlignment:
              isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            bubble,
            if (showTimestamp) ...[
              const SizedBox(height: 2),
              _Footer(
                time: ChatDateFormatter.bubbleTime(message.createdAt),
                isSelf: isSelf,
                isDark: isDark,
                showReadReceipt: showReadReceipt && isSelf,
                isRead: message.isRead,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.time,
    required this.isSelf,
    required this.isDark,
    required this.showReadReceipt,
    required this.isRead,
  });

  final String time;
  final bool isSelf;
  final bool isDark;
  final bool showReadReceipt;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final readColor =
        isDark ? DeelmarktColors.darkTrustEscrow : DeelmarktColors.trustEscrow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        if (showReadReceipt) ...[
          const SizedBox(width: 4),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: isRead ? readColor : color,
            semanticLabel: 'chat.readReceiptA11y'.tr(),
          ),
        ],
      ],
    );
  }
}
