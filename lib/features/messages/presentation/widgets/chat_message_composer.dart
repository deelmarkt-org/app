import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// P-36 — Sticky bottom composer for the chat thread.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md` §Input bar.
/// Sends a message when the user taps the primary send button. The
/// parent notifier is responsible for the actual API call and optimistic
/// state update.
class ChatMessageComposer extends StatefulWidget {
  const ChatMessageComposer({
    required this.onSend,
    required this.isSending,
    this.onCameraTap,
    this.onMakeOfferTap,
    super.key,
  });

  /// Called with the (untrimmed) text when the user taps send.
  final void Function(String text) onSend;
  final bool isSending;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMakeOfferTap;

  @override
  State<ChatMessageComposer> createState() => _ChatMessageComposerState();
}

/// State holds only the [TextEditingController] (a [Listenable]). The send
/// button rebuilds via [ListenableBuilder] bound to the controller, so the
/// widget never calls a State rebuild method — composer input is ephemeral
/// per-widget UI state, not app state, and CLAUDE.md §1.3's Riverpod rule
/// is satisfied by using the controller as the sole reactive source.
class _ChatMessageComposerState extends State<ChatMessageComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white;
    final border =
        isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200;
    final fieldBg =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral50;
    final hintColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final iconColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s3,
          vertical: Spacing.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: widget.onCameraTap,
              icon: Icon(Icons.camera_alt_outlined, color: iconColor),
              tooltip: 'chat.cameraA11y'.tr(),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(DeelmarktRadius.full),
                  border: Border.all(color: border),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.s4,
                  vertical: Spacing.s2,
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  // Bound the payload to a sane upper limit — pre-empts
                  // wasteful regex work in offer_message_card.dart and
                  // keeps request bodies bounded (security finding F-07).
                  // Server-side validation remains the source of truth.
                  maxLength: 4000,
                  style: theme.textTheme.bodyLarge,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'chat.typeMessage'.tr(),
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: hintColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.s2),
            TextButton(
              onPressed: widget.onMakeOfferTap,
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark
                        ? DeelmarktColors.darkPrimary
                        : DeelmarktColors.primary,
                minimumSize: const Size(44, 44),
              ),
              child: Text('chat.offer'.tr()),
            ),
            const SizedBox(width: Spacing.s1),
            // Rebuilds only when the controller text changes.
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final hasText = _controller.text.trim().isNotEmpty;
                return _SendButton(
                  enabled: hasText && !widget.isSending,
                  busy: widget.isSending,
                  onPressed: _handleSend,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        enabled ? DeelmarktColors.primary : DeelmarktColors.neutral300;
    return Semantics(
      button: true,
      label: 'chat.sendA11y'.tr(),
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child:
                busy
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          DeelmarktColors.white,
                        ),
                      ),
                    )
                    : const Icon(
                      Icons.arrow_upward,
                      color: DeelmarktColors.white,
                      size: 22,
                    ),
          ),
        ),
      ),
    );
  }
}
