import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_notifier.dart'
    show ChatThreadState, chatThreadNotifierProvider;
import 'package:deelmarkt/features/messages/presentation/widgets/chat_error_view.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_thread_body.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/make_offer_sheet.dart';

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
  static const _logTag = 'ChatThreadScreen';
  static const _errorTitleKey = 'messages.errorTitle';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _handleMakeOffer() async {
    final cents = await MakeOfferSheet.show(context);
    if (cents == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorLabel = _errorTitleKey.tr();
    try {
      await ref
          .read(chatThreadNotifierProvider(widget.conversationId).notifier)
          .sendOffer(cents);
    } on Exception catch (e) {
      if (!mounted) return;
      AppLogger.error('sendOffer failed', tag: _logTag, error: e);
      messenger.showSnackBar(SnackBar(content: Text(errorLabel)));
    }
  }

  Future<void> _handleOfferRespond(
    String messageId,
    OfferStatus response,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorLabel = _errorTitleKey.tr();
    try {
      await ref
          .read(chatThreadNotifierProvider(widget.conversationId).notifier)
          .updateOfferStatus(messageId, response);
    } on Exception catch (e) {
      if (!mounted) return;
      AppLogger.error('updateOfferStatus failed', tag: _logTag, error: e);
      messenger.showSnackBar(SnackBar(content: Text(errorLabel)));
    }
  }

  Future<void> _handleSend(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorLabel = _errorTitleKey.tr();
    try {
      await ref
          .read(chatThreadNotifierProvider(widget.conversationId).notifier)
          .sendText(text);
    } on Exception catch (e) {
      if (!mounted) return;
      AppLogger.error('sendText failed', tag: _logTag, error: e);
      messenger.showSnackBar(SnackBar(content: Text(errorLabel)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatThreadNotifierProvider(widget.conversationId));
    final colors = ChatThemeColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    ref.listen(chatThreadNotifierProvider(widget.conversationId), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount <= prevCount) return;
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
    return ChatThreadBody(
      state: state,
      colors: colors,
      scrollController: _scrollController,
      currentUserId: ref.watch(currentUserProvider)?.id ?? '',
      showBackButton: widget.showBackButton,
      onOfferRespond: _handleOfferRespond,
      onSend: _handleSend,
      onCameraTap:
          () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('chat.comingSoon'.tr()),
              behavior: SnackBarBehavior.floating,
            ),
          ),
      onMakeOfferTap: _handleMakeOffer,
    );
  }
}
