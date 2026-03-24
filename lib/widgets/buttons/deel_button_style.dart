import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'deel_button.dart';
import 'deel_button_tokens.dart';

/// Resolves [ButtonStyle] for [DeelButton] based on variant, size, and theme.
///
/// Extracted from DeelButton to keep widget file under CLAUDE.md §2.1 limit.
class DeelButtonStyleResolver {
  const DeelButtonStyleResolver({
    required this.variant,
    required this.size,
    required this.fullWidth,
    required this.theme,
  });

  final DeelButtonVariant variant;
  final DeelButtonSize size;
  final bool fullWidth;
  final DeelButtonThemeData theme;

  /// Resolve the full [ButtonStyle] for the current variant/size/theme.
  ButtonStyle resolve() {
    return ButtonStyle(
      backgroundColor: _resolveBackground(),
      foregroundColor: _resolveForeground(),
      overlayColor: _resolveOverlay(),
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, DeelButtonTokens.heightFor(size)),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: DeelButtonTokens.paddingFor(size)),
      ),
      shape: _resolveShape(),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: DeelmarktTypography.fontFamily,
          fontSize: DeelButtonTokens.fontSizeFor(size),
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // ── Style constants ─────────────────────────────────────────────────

  static const double _kDisabledAlpha = 0.4;
  static const Color _kPressedBgOverlay = Color(0x1A000000); // 10% black
  static const double _kPressedFocusedAlpha = 0.08;
  static const double _kHoveredAlpha = 0.04;

  // ── State resolvers (extracted to reduce cognitive complexity) ────────

  WidgetStateProperty<Color?> _resolveBackground() {
    final Color bg = backgroundFor(variant);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return bg.withValues(alpha: _kDisabledAlpha);
      }
      if (states.contains(WidgetState.pressed)) {
        return Color.alphaBlend(_kPressedBgOverlay, bg);
      }
      return bg;
    });
  }

  WidgetStateProperty<Color?> _resolveForeground() {
    final Color fg = foregroundFor(variant);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return fg.withValues(alpha: _kDisabledAlpha);
      }
      return fg;
    });
  }

  WidgetStateProperty<Color?> _resolveOverlay() {
    final Color fg = foregroundFor(variant);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return fg.withValues(alpha: _kPressedFocusedAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return fg.withValues(alpha: _kHoveredAlpha);
      }
      if (states.contains(WidgetState.focused)) {
        return fg.withValues(alpha: _kPressedFocusedAlpha);
      }
      return Colors.transparent;
    });
  }

  WidgetStateProperty<OutlinedBorder?> _resolveShape() {
    final borderRadius = BorderRadius.circular(DeelmarktRadius.lg);
    return WidgetStateProperty.resolveWith((states) {
      final BorderSide side = _resolveBorderSide(states);
      return RoundedRectangleBorder(borderRadius: borderRadius, side: side);
    });
  }

  BorderSide _resolveBorderSide(Set<WidgetState> states) {
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: theme.primaryBackground, width: 2);
    }
    if (variant == DeelButtonVariant.outline) {
      return BorderSide(color: borderColorFor(variant), width: 1.5);
    }
    return BorderSide.none;
  }

  // ── Colour resolvers ───────────────────────────────────────────────────

  /// Background colour for [variant].
  Color backgroundFor(DeelButtonVariant v) => switch (v) {
    DeelButtonVariant.primary => theme.primaryBackground,
    DeelButtonVariant.secondary => theme.secondaryBackground,
    DeelButtonVariant.outline => Colors.transparent,
    DeelButtonVariant.ghost => Colors.transparent,
    DeelButtonVariant.destructive => theme.destructiveBackground,
    DeelButtonVariant.success => theme.successBackground,
  };

  /// Foreground colour for [variant].
  Color foregroundFor(DeelButtonVariant v) => switch (v) {
    DeelButtonVariant.primary => theme.primaryForeground,
    DeelButtonVariant.secondary => theme.secondaryForeground,
    DeelButtonVariant.outline => theme.outlineForeground,
    DeelButtonVariant.ghost => theme.ghostForeground,
    DeelButtonVariant.destructive => theme.destructiveForeground,
    DeelButtonVariant.success => theme.successForeground,
  };

  /// Border colour for [variant].
  Color borderColorFor(DeelButtonVariant v) => switch (v) {
    DeelButtonVariant.outline => theme.outlineBorderColor,
    _ => Colors.transparent,
  };
}
