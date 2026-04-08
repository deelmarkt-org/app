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

/// P-36 / R-32 — Structured offer card for `MessageType.offer`.
///
/// [onRespond] is called when the seller taps Accept or Decline. It is null
/// for the buyer (isSelf = true) or once the offer is resolved.
/// Counter offer is deferred to E03 transaction module (still shows comingSoon).
///
/// SECURITY: [onRespond] must never call any payment or transaction API.
class OfferMessageCard extends StatelessWidget {
  const OfferMessageCard({
    required this.message,
    required this.isSelf,
    this.onRespond,
    super.key,
  });

  final MessageEntity message;
  final bool isSelf;

  /// Called with [OfferStatus.accepted] or [OfferStatus.declined].
  /// Null when the viewer is the buyer or the offer is already resolved.
  final void Function(OfferStatus)? onRespond;

  String _formattedAmount(BuildContext context) {
    final cents = message.offerAmountCents;
    if (cents == null) return '€ —';
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: '€ ',
      decimalDigits: 2,
    ).format(cents / 100);
  }

  void _showComingSoon(BuildContext context, String action) {
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
                  'chat.offerOf'.tr(
                    namedArgs: {'amount': _formattedAmount(context)},
                  ),
                  style: DeelmarktTypography.priceSm.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Spacing.s3),
                if (message.offerStatus == OfferStatus.pending)
                  _PendingActions(
                    onRespond: onRespond,
                    onCounter: (ctx) => _showComingSoon(ctx, 'counter'),
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
  const _PendingActions({required this.onRespond, required this.onCounter});

  final void Function(OfferStatus)? onRespond;
  final void Function(BuildContext) onCounter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed:
                    onRespond != null
                        ? () => onRespond!(OfferStatus.accepted)
                        : null,
                style: FilledButton.styleFrom(
                  backgroundColor: DeelmarktColors.success,
                  foregroundColor: DeelmarktColors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DeelmarktRadius.md),
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: 'chat.accept'.tr(),
                  child: Text('chat.accept'.tr()),
                ),
              ),
            ),
            const SizedBox(width: Spacing.s2),
            Expanded(
              child: OutlinedButton(
                onPressed:
                    onRespond != null
                        ? () => onRespond!(OfferStatus.declined)
                        : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: DeelmarktColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DeelmarktRadius.md),
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: 'chat.decline'.tr(),
                  child: Text('chat.decline'.tr()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.s2),
        TextButton(
          onPressed: () => onCounter(context),
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
