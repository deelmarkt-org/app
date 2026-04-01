import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar_tokens.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';

/// Size variants for [DeelAvatar].
enum DeelAvatarSize {
  small, // 32px
  medium, // 48px
  large, // 80px
}

/// Circular avatar with 4 states, optional badge overlay, and edit overlay.
///
/// States:
/// - **Placeholder**: initials from [displayName], hashed background colour
/// - **Loading**: shimmer circle (caller wraps in [SkeletonLoader])
/// - **Loaded**: network image with fade-in
/// - **Error**: falls back to initials
///
/// Reference: docs/design-system/components.md §Avatar
class DeelAvatar extends StatelessWidget {
  const DeelAvatar({
    required this.displayName,
    this.imageUrl,
    this.size = DeelAvatarSize.medium,
    this.badgeType,
    this.showEditOverlay = false,
    this.onEditTap,
    super.key,
  });

  /// Display name — used for initials fallback.
  final String displayName;

  /// Network image URL. `null` triggers placeholder state.
  final String? imageUrl;

  /// Avatar size. Defaults to [DeelAvatarSize.medium].
  final DeelAvatarSize size;

  /// Optional badge overlay positioned bottom-right.
  final DeelBadgeType? badgeType;

  /// Show semi-transparent edit overlay with camera icon.
  final bool showEditOverlay;

  /// Callback when edit overlay is tapped.
  final VoidCallback? onEditTap;

  double get _diameter => switch (size) {
    DeelAvatarSize.small => DeelAvatarTokens.sizeSmall,
    DeelAvatarSize.medium => DeelAvatarTokens.sizeMedium,
    DeelAvatarSize.large => DeelAvatarTokens.sizeLarge,
  };

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = _buildImageAvatar(context, reduceMotion);
    } else {
      avatar = _buildInitialsAvatar(context);
    }

    Widget result = SizedBox(
      width: _diameter,
      height: _diameter,
      child: avatar,
    );

    if (showEditOverlay) {
      result = GestureDetector(
        onTap: onEditTap,
        child: Stack(
          children: [result, Positioned.fill(child: _buildEditOverlay())],
        ),
      );
    }

    if (badgeType != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          Positioned(
            bottom: DeelAvatarTokens.badgeOffset,
            right: DeelAvatarTokens.badgeOffset,
            child: DeelBadge(
              type: badgeType!,
              size: DeelBadgeSize.small,
              showTooltip: false,
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: displayName,
      image: imageUrl != null,
      child: result,
    );
  }

  Widget _buildImageAvatar(BuildContext context, bool reduceMotion) {
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.standard,
      reduceMotion: reduceMotion,
    );

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: _diameter,
        height: _diameter,
        fit: BoxFit.cover,
        cacheWidth:
            (_diameter * MediaQuery.devicePixelRatioOf(context)).toInt(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: duration,
              curve: DeelmarktAnimation.curveStandard,
              child: child,
            );
          }
          return _buildInitialsAvatar(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(context);
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = _extractInitials(displayName);
    final bgColor = _backgroundFromName(displayName);
    final textStyle = _initialsTextStyle(context);

    return ClipOval(
      child: Container(
        width: _diameter,
        height: _diameter,
        color: bgColor,
        alignment: Alignment.center,
        child: Text(
          initials,
          style: textStyle.copyWith(color: DeelmarktColors.white),
        ),
      ),
    );
  }

  Widget _buildEditOverlay() {
    return ClipOval(
      child: Container(
        color: Colors.black.withValues(
          alpha: DeelAvatarTokens.editOverlayOpacity,
        ),
        alignment: Alignment.center,
        child: const Icon(
          PhosphorIconsBold.camera,
          color: DeelmarktColors.white,
          size: DeelAvatarTokens.editIconSize,
        ),
      ),
    );
  }

  TextStyle _initialsTextStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return switch (size) {
      DeelAvatarSize.small => theme.bodySmall ?? const TextStyle(fontSize: 12),
      DeelAvatarSize.medium =>
        theme.bodyMedium ?? const TextStyle(fontSize: 14),
      DeelAvatarSize.large =>
        theme.headlineMedium ?? const TextStyle(fontSize: 24),
    };
  }

  static String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _backgroundFromName(String name) {
    final colors = [
      const Color(0xFF1E4F7A), // secondary
      const Color(0xFFF15A24), // primary
      const Color(0xFF16A34A), // verified green
      const Color(0xFF2563EB), // escrow blue
      const Color(0xFFD97706), // gold
      const Color(0xFF7C3AED), // purple
      const Color(0xFFDB2777), // pink
      const Color(0xFF059669), // emerald
    ];
    final hash = name.codeUnits.fold<int>(0, (h, c) => h + c);
    return colors[hash % colors.length];
  }
}
