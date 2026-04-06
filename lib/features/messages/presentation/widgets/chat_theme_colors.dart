import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Centralised theme-aware color resolver for the chat feature.
///
/// Every chat widget reads its colors from here instead of hand-writing
/// `isDark ? DeelmarktColors.darkX : DeelmarktColors.X` ternaries. Removing
/// the per-widget duplication kills ~26 nested-ternary expressions and
/// keeps dark-mode evolution in a single place (one file to change when a
/// new token pair is added).
///
/// Usage:
/// ```dart
/// final colors = ChatThemeColors.of(context);
/// return Container(color: colors.surface, child: ...);
/// ```
///
/// Accessing the resolver once at the top of `build()` is cheap — it is
/// a plain value object holding one `bool`. No BuildContext is retained.
class ChatThemeColors {
  const ChatThemeColors._(this.isDark);

  factory ChatThemeColors.of(BuildContext context) =>
      ChatThemeColors._(Theme.of(context).brightness == Brightness.dark);

  final bool isDark;

  // ── Bubbles & chat-specific surfaces ──
  Color get bubbleSelfBg =>
      isDark
          ? DeelmarktColors.darkChatSelfBubble
          : DeelmarktColors.primarySurface;

  Color get bubbleOtherBg =>
      isDark ? DeelmarktColors.darkChatOtherBubble : DeelmarktColors.neutral100;

  // ── Text ──
  Color get textPrimary =>
      isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900;

  Color get textSecondary =>
      isDark
          ? DeelmarktColors.darkOnSurfaceSecondary
          : DeelmarktColors.neutral700;

  Color get textTertiary =>
      isDark
          ? DeelmarktColors.darkOnSurfaceSecondary
          : DeelmarktColors.neutral500;

  // ── Surfaces ──
  Color get surface =>
      isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white;

  Color get surfaceMuted =>
      isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral50;

  Color get surfaceElevated =>
      isDark ? DeelmarktColors.darkSurfaceElevated : DeelmarktColors.neutral100;

  Color get scaffold =>
      isDark ? DeelmarktColors.darkScaffold : DeelmarktColors.neutral50;

  Color get border =>
      isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200;

  // ── Brand / state ──
  Color get primary =>
      isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary;

  Color get success =>
      isDark ? DeelmarktColors.darkSuccess : DeelmarktColors.success;

  Color get successSurface =>
      isDark
          ? DeelmarktColors.darkSuccessSurface
          : DeelmarktColors.successSurface;

  Color get readReceipt =>
      isDark ? DeelmarktColors.darkTrustEscrow : DeelmarktColors.trustEscrow;

  // ── Skeleton shimmer pair ──
  Color get shimmerBase =>
      isDark ? DeelmarktColors.darkSurfaceElevated : DeelmarktColors.neutral100;

  Color get shimmerHighlight =>
      isDark ? DeelmarktColors.darkShimmerHighlight : DeelmarktColors.neutral50;

  Color get shimmerPlaceholder =>
      isDark ? DeelmarktColors.darkSurfaceElevated : DeelmarktColors.neutral200;

  /// Selected-row background for the expanded master-detail layout.
  Color get selectedRowBg =>
      isDark
          ? DeelmarktColors.darkSurfaceElevated
          : DeelmarktColors.primarySurface;
}
