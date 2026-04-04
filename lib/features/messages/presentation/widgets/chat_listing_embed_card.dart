import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

/// P-36 — Pinned listing context card at the top of the chat thread.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md` §Listing embed.
/// Shows a 40×40 thumbnail, listing title, price placeholder and status chip.
class ChatListingEmbedCard extends StatelessWidget {
  const ChatListingEmbedCard({required this.conversation, super.key});

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral50;
    final border =
        isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200;
    final titleColor =
        isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900;
    final priceColor =
        isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary;

    return Semantics(
      label: 'chat.listingEmbedA11y'.tr(
        namedArgs: {'title': conversation.listingTitle},
      ),
      child: Container(
        margin: const EdgeInsets.all(Spacing.s4),
        padding: const EdgeInsets.all(Spacing.s3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            _Thumb(url: conversation.listingImageUrl, isDark: isDark),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation.listingTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.s1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          // TODO(messages): once the entity exposes price,
                          // render it here via CurrencyFormatter.
                          '€ —',
                          style: DeelmarktTypography.priceSm.copyWith(
                            color: priceColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Spacing.s2),
                      Flexible(child: _StatusChip(isDark: isDark)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.isDark});

  final String? url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral100;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        image:
            url != null && url!.isNotEmpty
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
      ),
      child:
          url == null || url!.isEmpty
              ? Icon(
                Icons.image_outlined,
                size: 20,
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurfaceSecondary
                        : DeelmarktColors.neutral500,
              )
              : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? DeelmarktColors.darkSuccessSurface
            : DeelmarktColors.successSurface;
    final fg = isDark ? DeelmarktColors.darkSuccess : DeelmarktColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s2, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        'chat.statusForSale'.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
