import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';

/// Private sub-widgets for [ConversationListTile].
///
/// Extracted to keep the tile file under the 200-line widget limit (§2.1).
/// These classes are intentionally not exported — only [ConversationListTile]
/// should import this file.

class ConversationListTileAvatar extends StatelessWidget {
  const ConversationListTileAvatar({
    required this.url,
    required this.isOnline,
    required this.colors,
    super.key,
  });

  final String? url;
  final bool isOnline;
  final ChatThemeColors colors;

  bool get _hasImage => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBase(),
          Positioned(right: 2, bottom: 2, child: _buildPresenceDot()),
        ],
      ),
    );
  }

  Widget _buildBase() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        shape: BoxShape.circle,
        image:
            _hasImage
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
      ),
      child:
          _hasImage
              ? null
              : Icon(
                Icons.person,
                size: DeelmarktIconSize.lg,
                color: colors.textTertiary,
              ),
    );
  }

  Widget _buildPresenceDot() {
    final dotColor = isOnline ? colors.success : colors.textTertiary;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
    );
  }
}

class ConversationListTileListingChip extends StatelessWidget {
  const ConversationListTileListingChip({
    required this.title,
    required this.colors,
    super.key,
  });

  final String title;
  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class ConversationListTileListingThumb extends StatelessWidget {
  const ConversationListTileListingThumb({
    required this.url,
    required this.colors,
    super.key,
  });

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
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        image:
            _hasImage
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
        border: Border.all(color: colors.border),
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

class ConversationListTileUnreadBadge extends StatelessWidget {
  const ConversationListTileUnreadBadge({
    required this.count,
    required this.colors,
    super.key,
  });

  final int count;
  final ChatThemeColors colors;

  /// Shared constant so the placeholder [SizedBox] in the trailing column
  /// stays in sync with the badge height, preventing layout shifts.
  static const double minBadgeHeight = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: minBadgeHeight,
        minHeight: minBadgeHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DeelmarktColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
