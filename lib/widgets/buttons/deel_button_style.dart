import 'package:flutter/material.dart';

import '../../core/design_system/deel_button_theme.dart';
import '../../core/design_system/radius.dart';
import '../../core/design_system/typography.dart';
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
    final Color background = backgroundFor(variant);
    final Color foreground = foregroundFor(variant);

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return background.withValues(alpha: 0.4);
        }
        if (states.contains(WidgetState.pressed)) {
          return Color.alphaBlend(
            const Color(0x1A000000), // 10% darker overlay
            background,
          );
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return foreground.withValues(alpha: 0.4);
        }
        return foreground;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return foreground.withValues(alpha: 0.04);
        }
        if (states.contains(WidgetState.focused)) {
          return foreground.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, DeelButtonTokens.heightFor(size)),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: DeelButtonTokens.paddingFor(size)),
      ),
      shape: WidgetStateProperty.resolveWith((states) {
        final BorderSide focusSide =
            states.contains(WidgetState.focused)
                ? BorderSide(color: theme.primaryBackground, width: 2)
                : variant == DeelButtonVariant.outline
                ? BorderSide(color: borderColorFor(variant), width: 1.5)
                : BorderSide.none;

        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          side: focusSide,
        );
      }),
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
