import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

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
    final colors = ChatThemeColors.of(context);
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    final bubbleColor = isSelf ? colors.bubbleSelfBg : colors.bubbleOtherBg;

    return Semantics(
      label: _semanticLabel(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s4,
          vertical: Spacing.s1,
        ),
        child: Column(
          crossAxisAlignment:
              isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildBubble(theme, colors, bubbleColor, maxBubbleWidth),
            if (showTimestamp) ...[
              const SizedBox(height: 2),
              _Footer(
                time: ChatDateFormatter.bubbleTime(message.createdAt),
                isSelf: isSelf,
                colors: colors,
                showReadReceipt: showReadReceipt && isSelf,
                isRead: message.isRead,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    ThemeData theme,
    ChatThemeColors colors,
    Color bubbleColor,
    double maxWidth,
  ) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(DeelmarktRadius.xl),
      topRight: const Radius.circular(DeelmarktRadius.xl),
      bottomLeft: Radius.circular(
        isSelf ? DeelmarktRadius.xl : DeelmarktRadius.xs,
      ),
      bottomRight: Radius.circular(
        isSelf ? DeelmarktRadius.xs : DeelmarktRadius.xl,
      ),
    );
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
      child: Text(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
      ),
    );
  }

  String _semanticLabel() {
    final key = isSelf ? 'chat.selfBubbleA11y' : 'chat.otherBubbleA11y';
    return key.tr(namedArgs: {'text': message.text});
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.time,
    required this.isSelf,
    required this.colors,
    required this.showReadReceipt,
    required this.isRead,
  });

  final String time;
  final bool isSelf;
  final ChatThemeColors colors;
  final bool showReadReceipt;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        if (showReadReceipt) ...[
          const SizedBox(width: Spacing.s1),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: isRead ? colors.readReceipt : colors.textTertiary,
            semanticLabel: 'chat.readReceiptA11y'.tr(),
          ),
        ],
      ],
    );
  }
}
