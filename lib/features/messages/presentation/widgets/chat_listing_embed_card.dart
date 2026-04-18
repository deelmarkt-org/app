import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

/// P-36 — Pinned listing context card at the top of the chat thread.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md` §Listing embed.
/// Shows a 48x48 thumbnail, listing title, price placeholder and status chip.
class ChatListingEmbedCard extends StatelessWidget {
  const ChatListingEmbedCard({required this.conversation, super.key});

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ChatThemeColors.of(context);

    return Semantics(
      label: 'chat.listingEmbedA11y'.tr(
        namedArgs: {'title': conversation.listingTitle},
      ),
      child: Container(
        margin: const EdgeInsets.all(Spacing.s4),
        padding: const EdgeInsets.all(Spacing.s3),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            _Thumb(url: conversation.listingImageUrl, colors: colors),
            const SizedBox(width: Spacing.s3),
            Expanded(child: _buildTextColumn(theme, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextColumn(ThemeData theme, ChatThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          conversation.listingTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
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
                  color: colors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Spacing.s2),
            Flexible(child: _StatusChip(colors: colors)),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.colors});

  final String? url;
  final ChatThemeColors colors;

  bool get _hasImage => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        image:
            _hasImage
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
      ),
      child:
          _hasImage
              ? null
              : Icon(
                Icons.image_outlined,
                size: DeelmarktIconSize.sm,
                color: colors.textTertiary,
              ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.colors});

  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s2, vertical: 2),
      decoration: BoxDecoration(
        color: colors.successSurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        'chat.statusForSale'.tr(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
