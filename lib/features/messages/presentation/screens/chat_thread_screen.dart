import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_notifier.dart'
    show chatThreadNotifierProvider, kCurrentUserIdStub;
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_thread_list.dart';

/// P-36 — Chat thread screen.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md`.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    required this.conversationId,
    this.showBackButton = true,
    super.key,
  });

  final String conversationId;

  /// Hidden in the expanded master-detail layout (right pane has no back).
  final bool showBackButton;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('chat.comingSoon'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatThreadNotifierProvider(widget.conversationId));
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Auto-scroll whenever message count changes.
    ref.listen(chatThreadNotifierProvider(widget.conversationId), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount != prevCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animated: !reduceMotion);
        });
      }
    });

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, _) => _ThreadError(
            onRetry:
                () => ref.invalidate(
                  chatThreadNotifierProvider(widget.conversationId),
                ),
          ),
      data: (state) {
        final bodyColor =
            theme.brightness == Brightness.dark
                ? DeelmarktColors.darkScaffold
                : DeelmarktColors.neutral50;
        return Container(
          color: bodyColor,
          child: Column(
            children: [
              ChatHeader(
                conversation: state.conversation,
                showBackButton: widget.showBackButton,
              ),
              ChatListingEmbedCard(conversation: state.conversation),
              // P-37 SCOPE BOUNDARY: scam-alert banner reserved slot.
              // The widget for this slot ships with P-37.
              const SizedBox.shrink(),
              Expanded(
                child: ChatThreadList(
                  scrollController: _scrollController,
                  messages: state.messages,
                  currentUserId: kCurrentUserIdStub,
                ),
              ),
              ChatMessageComposer(
                isSending: state.isSending,
                onSend: (text) {
                  ref
                      .read(
                        chatThreadNotifierProvider(
                          widget.conversationId,
                        ).notifier,
                      )
                      .sendText(text)
                      .catchError((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('messages.errorTitle'.tr())),
                        );
                      });
                },
                onCameraTap: () => _showComingSoon(context),
                onMakeOfferTap: () => _showComingSoon(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'messages.errorTitle'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s4),
            FilledButton(
              onPressed: onRetry,
              child: Text('messages.errorRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
