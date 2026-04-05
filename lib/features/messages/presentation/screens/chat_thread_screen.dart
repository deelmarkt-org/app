import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_notifier.dart'
    show ChatThreadState, chatThreadNotifierProvider, kCurrentUserIdStub;
import 'package:deelmarkt/features/messages/presentation/widgets/chat_error_view.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_thread_list.dart';

/// Pixel threshold beneath which the user is considered "at the bottom"
/// for the purposes of sticky auto-scroll (Gemini code review G2).
const double _kAutoScrollThresholdPx = 100;

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

  /// Returns `true` if the user is currently scrolled within
  /// [_kAutoScrollThresholdPx] of the bottom of the thread. Defaults to
  /// `true` when the controller has no clients yet (first render) — we
  /// want new messages to land at the bottom on initial load.
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < _kAutoScrollThresholdPx;
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

  void _handleSend(String text) {
    // Capture the messenger synchronously — avoids touching BuildContext
    // after the async gap (use_build_context_synchronously lint).
    final messenger = ScaffoldMessenger.of(context);
    final errorLabel = 'messages.errorTitle'.tr();
    ref
        .read(chatThreadNotifierProvider(widget.conversationId).notifier)
        .sendText(text)
        .catchError((_) {
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(content: Text(errorLabel)));
        });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatThreadNotifierProvider(widget.conversationId));
    final colors = ChatThemeColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Auto-scroll whenever new messages arrive, but only if the user is
    // already near the bottom — don't jerk the viewport away from someone
    // reading older messages (Gemini code review G2).
    ref.listen(chatThreadNotifierProvider(widget.conversationId), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount <= prevCount) return;
      // Capture the position decision BEFORE the post-frame callback so
      // that the user's scroll position at "now" is what drives the rule.
      final shouldStick = _isNearBottom();
      if (!shouldStick) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: !reduceMotion);
      });
    });

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, _) => ChatErrorView(
            onRetry:
                () => ref.invalidate(
                  chatThreadNotifierProvider(widget.conversationId),
                ),
          ),
      data: (state) => _buildLoaded(state, colors),
    );
  }

  Widget _buildLoaded(ChatThreadState state, ChatThemeColors colors) {
    return Container(
      color: colors.scaffold,
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
            onSend: _handleSend,
            onCameraTap: () => _showComingSoon(context),
            onMakeOfferTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }
}
