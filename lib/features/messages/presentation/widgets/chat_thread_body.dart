import 'package:flutter/material.dart';

import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_scam_alert_slot.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_thread_list.dart';

/// The loaded body of a chat thread: header, listing embed, scam alert
/// banner, message list, and composer bar.
///
/// All data is passed in as resolved values; side-effect callbacks are
/// provided by the parent screen. This keeps the widget independently
/// testable without a [ProviderScope] (D2 — StatelessWidget default).
///
/// Reference: docs/screens/06-chat/02-chat-thread.md
class ChatThreadBody extends StatelessWidget {
  const ChatThreadBody({
    required this.state,
    required this.colors,
    required this.scrollController,
    required this.currentUserId,
    required this.showBackButton,
    required this.onOfferRespond,
    required this.onSend,
    required this.onCameraTap,
    required this.onMakeOfferTap,
    super.key,
  });

  final ChatThreadState state;
  final ChatThemeColors colors;
  final ScrollController scrollController;
  final String currentUserId;
  final bool showBackButton;
  final void Function(String messageId, OfferStatus response) onOfferRespond;
  final void Function(String text) onSend;
  final VoidCallback onCameraTap;
  final VoidCallback onMakeOfferTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.scaffold,
      child: Column(
        children: [
          ChatHeader(
            conversation: state.conversation,
            showBackButton: showBackButton,
          ),
          ChatListingEmbedCard(conversation: state.conversation),
          ChatScamAlertSlot(state: state),
          Expanded(
            child: ChatThreadList(
              scrollController: scrollController,
              messages: state.messages,
              currentUserId: currentUserId,
              onOfferRespond: onOfferRespond,
            ),
          ),
          ChatMessageComposer(
            isSending: state.isSending,
            onSend: onSend,
            onCameraTap: onCameraTap,
            onMakeOfferTap: onMakeOfferTap,
          ),
        ],
      ),
    );
  }
}
