import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_day_separator.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/message_bubble.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/offer_message_card.dart';

/// Scrollable thread list — groups messages by day, renders text and
/// structured offer bubbles, and shows a read receipt under the last
/// consecutive self bubble.
class ChatThreadList extends StatelessWidget {
  const ChatThreadList({
    required this.scrollController,
    required this.messages,
    required this.currentUserId,
    super.key,
  });

  final ScrollController scrollController;
  final List<MessageEntity> messages;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: _EmptyThread());
    }

    // Single `now` for the whole frame so day-separators at the day boundary
    // render consistently (review finding M#3).
    final now = DateTime.now();

    // TODO(perf): memoise this transform in the notifier if threads grow
    // beyond a few hundred messages (review finding M#4).
    final items = <_ThreadItem>[];
    DateTime? lastDay;
    for (final m in messages) {
      final day = DateTime(
        m.createdAt.year,
        m.createdAt.month,
        m.createdAt.day,
      );
      if (lastDay == null || day != lastDay) {
        items.add(_DaySeparatorItem(day: m.createdAt));
        lastDay = day;
      }
      items.add(_MessageItem(message: m, isSelf: m.senderId == currentUserId));
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _DaySeparatorItem) {
          return ChatDaySeparator(moment: item.day, now: now);
        }
        if (item is _MessageItem) {
          final msg = item.message;
          final nextIsSelf = _nextMessageIsSelf(items, index);
          final showReceipt = item.isSelf && !nextIsSelf;
          if (msg.type == MessageType.offer) {
            return OfferMessageCard(message: msg, isSelf: item.isSelf);
          }
          return MessageBubble(
            message: msg,
            isSelf: item.isSelf,
            showReadReceipt: showReceipt,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  bool _nextMessageIsSelf(List<_ThreadItem> items, int index) {
    for (var i = index + 1; i < items.length; i++) {
      final next = items[i];
      if (next is _MessageItem) return next.isSelf;
    }
    return false;
  }
}

sealed class _ThreadItem {
  const _ThreadItem();
}

class _DaySeparatorItem extends _ThreadItem {
  const _DaySeparatorItem({required this.day});
  final DateTime day;
}

class _MessageItem extends _ThreadItem {
  const _MessageItem({required this.message, required this.isSelf});
  final MessageEntity message;
  final bool isSelf;
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.s6),
      child: Text(
        'chat.emptyThread'.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color:
              theme.brightness == Brightness.dark
                  ? DeelmarktColors.darkOnSurfaceSecondary
                  : DeelmarktColors.neutral500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
