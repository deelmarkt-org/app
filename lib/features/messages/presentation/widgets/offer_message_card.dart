import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

/// P-36 — Structured offer card for `MessageType.offer`.
///
/// Layout per `docs/screens/06-chat/02-chat-thread.md` §Structured offer.
/// The action buttons are rendered visually complete but their `onPressed`
/// handlers surface a localised "coming soon" SnackBar — the real
/// accept/decline/counter logic ships with the transaction module (E03)
/// in a follow-up task (see plan §13, Decision Q3).
///
/// SECURITY: These CTAs must never call any payment or transaction API.
class OfferMessageCard extends StatelessWidget {
  const OfferMessageCard({
    required this.message,
    required this.isSelf,
    super.key,
  });

  final MessageEntity message;
  final bool isSelf;

  /// Very small parser that extracts the amount string from messages like
  /// "Bod: € 120,00" — keeps us decoupled from adding a new entity field.
  String _amountOrFallback() {
    final match = RegExp(r'€\s?[0-9]+(?:[.,][0-9]+)*').firstMatch(message.text);
    return match?.group(0) ?? '€ —';
  }

  void _showComingSoon(BuildContext context, String action) {
    // Analytics intent event — Product uses this to prioritise P-36.1 order
    // (accept/decline/counter). Contains no PII — only the action token and
    // the literal word 'offer' (no conversation id, no user id, no text).
    AppLogger.info('offer_cta_intent:$action', tag: 'OfferMessageCard');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('chat.comingSoon'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s2,
      ),
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(Spacing.s4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
              border: Border.all(color: colors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'chat.offerOf'.tr(namedArgs: {'amount': _amountOrFallback()}),
                  style: DeelmarktTypography.priceSm.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Spacing.s3),
                if (message.offerStatus == OfferStatus.pending)
                  _PendingActions(
                    onTap: (action) => _showComingSoon(context, action),
                  )
                else
                  _StatusRow(
                    status: message.offerStatus ?? OfferStatus.pending,
                    colors: colors,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({required this.onTap});

  final void Function(String action) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => onTap('accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: DeelmarktColors.success,
                  foregroundColor: DeelmarktColors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DeelmarktRadius.md),
                  ),
                ),
                child: Text('chat.accept'.tr()),
              ),
            ),
            const SizedBox(width: Spacing.s2),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onTap('decline'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: DeelmarktColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DeelmarktRadius.md),
                  ),
                ),
                child: Text('chat.decline'.tr()),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.s2),
        TextButton(
          onPressed: () => onTap('counter'),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: Text('chat.counter'.tr()),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.colors});

  final OfferStatus status;
  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final accepted = status == OfferStatus.accepted;
    final color = accepted ? colors.success : colors.textTertiary;
    final icon = accepted ? Icons.check_circle : Icons.cancel;
    final label = accepted ? 'chat.accepted'.tr() : 'chat.declined'.tr();
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: Spacing.s2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
