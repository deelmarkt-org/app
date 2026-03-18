import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/deel_button_theme.dart';
import '../../core/design_system/radius.dart';
import '../../core/design_system/spacing.dart';
import '../../core/design_system/typography.dart';

/// Button variants for different action types.
/// Reference: docs/design-system/components.md §Buttons
enum DeelButtonVariant {
  /// Brand orange — "Koop nu", "Verkoop", "Betaal"
  primary,

  /// Blue — "Bericht sturen", "Bod doen"
  secondary,

  /// Transparent + 1.5px border — "Bekijk profiel", "Delen"
  outline,

  /// Transparent, no border — "Annuleren", "Overslaan"
  ghost,

  /// Red — "Account verwijderen"
  destructive,

  /// Green — "Levering bevestigen"
  success,
}

/// Button sizes with fixed heights and padding.
/// Reference: docs/design-system/components.md §Buttons
enum DeelButtonSize {
  /// Height: 52px, padding: 24px, font: 16px
  large,

  /// Height: 44px, padding: 16px, font: 14px
  medium,

  /// Height: 36px, padding: 12px, font: 13px
  small,
}

/// DeelMarkt button component.
///
/// Wraps Flutter's native [ElevatedButton], [OutlinedButton], or [TextButton]
/// with DeelMarkt design tokens, 6 variants, 3 sizes, and 5 states
/// (default, pressed, focused, disabled, loading).
///
/// Features:
/// - Variant colours via [DeelButtonThemeData] theme extension
/// - State resolution via [WidgetStateProperty]
/// - Loading state with [AnimatedSwitcher] crossfade
/// - Haptic feedback on CTA variants (primary, destructive, success)
/// - WCAG 2.2 AA: 44px min target, focus ring, screen reader labels
/// - Dynamic text scaling support
///
/// Reference: docs/design-system/components.md §Buttons
class DeelButton extends StatelessWidget {
  /// Creates a DeelMarkt button.
  ///
  /// [label] is the visible text. Should be pre-localised by the caller.
  /// [onPressed] fires on tap. Pass `null` to disable the button.
  /// [loadingLabel] is announced by screen readers when [isLoading] is true.
  const DeelButton({
    required this.label,
    required this.onPressed,
    this.variant = DeelButtonVariant.primary,
    this.size = DeelButtonSize.large,
    this.isLoading = false,
    this.loadingLabel,
    this.semanticDestructiveHint,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    super.key,
  });

  /// Button text — must be pre-localised (e.g. `'action.save'.tr()`).
  final String label;

  /// Callback on tap. Pass `null` to show disabled state.
  final VoidCallback? onPressed;

  /// Visual variant. Defaults to [DeelButtonVariant.primary].
  final DeelButtonVariant variant;

  /// Size variant. Defaults to [DeelButtonSize.large].
  final DeelButtonSize size;

  /// When `true`, a spinner replaces the label and interaction is disabled.
  final bool isLoading;

  /// Screen reader text announced during loading state.
  /// Falls back to [label] if not provided.
  final String? loadingLabel;

  /// Accessibility hint for destructive variant.
  /// Should be localised by the caller (e.g. `'Destructieve actie'`).
  final String? semanticDestructiveHint;

  /// Optional Phosphor icon before the label.
  final IconData? leadingIcon;

  /// Optional Phosphor icon after the label.
  final IconData? trailingIcon;

  /// Whether the button expands to fill its parent width.
  /// Defaults to `true` (mobile-first).
  final bool fullWidth;

  // ── Size tokens ────────────────────────────────────────────────────────

  double get _minHeight => switch (size) {
    DeelButtonSize.large => 52,
    DeelButtonSize.medium => 44,
    DeelButtonSize.small => 36,
  };

  double get _horizontalPadding => switch (size) {
    DeelButtonSize.large => Spacing.s6,
    DeelButtonSize.medium => Spacing.s4,
    DeelButtonSize.small => Spacing.s3,
  };

  double get _fontSize => switch (size) {
    DeelButtonSize.large => 16,
    DeelButtonSize.medium => 14,
    DeelButtonSize.small => 13,
  };

  double get _iconSize => switch (size) {
    DeelButtonSize.large => 20,
    DeelButtonSize.medium => 18,
    DeelButtonSize.small => 16,
  };

  // ── Haptic variants ────────────────────────────────────────────────────

  bool get _hasHaptic =>
      variant == DeelButtonVariant.primary ||
      variant == DeelButtonVariant.destructive ||
      variant == DeelButtonVariant.success;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final buttonTheme =
        Theme.of(context).extension<DeelButtonThemeData>() ??
        DeelButtonThemeData.light();
    final bool isDisabled = isLoading || onPressed == null;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    final ButtonStyle style = _resolveStyle(buttonTheme);
    final Widget child = _buildChild(context, reduceMotion, buttonTheme);

    final VoidCallback? effectiveOnPressed =
        isDisabled
            ? null
            : () {
              if (_hasHaptic) HapticFeedback.lightImpact();
              onPressed?.call();
            };

    // Wrap with Semantics for enhanced a11y.
    final Widget button = Semantics(
      button: true,
      label: isLoading ? (loadingLabel ?? label) : label,
      enabled: !isDisabled,
      hint:
          variant == DeelButtonVariant.destructive
              ? semanticDestructiveHint
              : null,
      excludeSemantics: true,
      child: _buildButtonByVariant(style, effectiveOnPressed, child),
    );

    return button;
  }

  // ── Variant → native button ────────────────────────────────────────────

  Widget _buildButtonByVariant(
    ButtonStyle style,
    VoidCallback? onPressed,
    Widget child,
  ) {
    return switch (variant) {
      DeelButtonVariant.outline => OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
      DeelButtonVariant.ghost => TextButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
      _ => ElevatedButton(style: style, onPressed: onPressed, child: child),
    };
  }

  // ── ButtonStyle ────────────────────────────────────────────────────────

  ButtonStyle _resolveStyle(DeelButtonThemeData theme) {
    final Color background = _backgroundFor(theme);
    final Color foreground = _foregroundFor(theme);

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return background.withValues(alpha: 0.4);
        }
        if (states.contains(WidgetState.pressed)) {
          return Color.alphaBlend(
            const Color(0x1A000000), // 10% darker
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
        Size(fullWidth ? double.infinity : 0, _minHeight),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: _horizontalPadding),
      ),
      shape: WidgetStateProperty.resolveWith((states) {
        final BorderSide focusSide =
            states.contains(WidgetState.focused)
                ? BorderSide(color: theme.primaryBackground, width: 2)
                : variant == DeelButtonVariant.outline
                ? BorderSide(color: _borderColorFor(theme), width: 1.5)
                : BorderSide.none;

        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          side: focusSide,
        );
      }),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: DeelmarktTypography.fontFamily,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // ── Colour resolvers ───────────────────────────────────────────────────

  Color _backgroundFor(DeelButtonThemeData theme) {
    return switch (variant) {
      DeelButtonVariant.primary => theme.primaryBackground,
      DeelButtonVariant.secondary => theme.secondaryBackground,
      DeelButtonVariant.outline => Colors.transparent,
      DeelButtonVariant.ghost => Colors.transparent,
      DeelButtonVariant.destructive => theme.destructiveBackground,
      DeelButtonVariant.success => theme.successBackground,
    };
  }

  Color _foregroundFor(DeelButtonThemeData theme) {
    return switch (variant) {
      DeelButtonVariant.primary => theme.primaryForeground,
      DeelButtonVariant.secondary => theme.secondaryForeground,
      DeelButtonVariant.outline => theme.outlineForeground,
      DeelButtonVariant.ghost => theme.ghostForeground,
      DeelButtonVariant.destructive => theme.destructiveForeground,
      DeelButtonVariant.success => theme.successForeground,
    };
  }

  Color _borderColorFor(DeelButtonThemeData theme) {
    return switch (variant) {
      DeelButtonVariant.outline => theme.outlineBorderColor,
      _ => Colors.transparent,
    };
  }

  // ── Child content ──────────────────────────────────────────────────────

  Widget _buildChild(
    BuildContext context,
    bool reduceMotion,
    DeelButtonThemeData buttonTheme,
  ) {
    final Duration duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          isLoading
              ? SizedBox(
                key: const ValueKey('loading'),
                width: _iconSize,
                height: _iconSize,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    _foregroundFor(buttonTheme),
                  ),
                ),
              )
              : _buildLabelRow(),
    );
  }

  Widget _buildLabelRow() {
    final List<Widget> children = [];

    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: _iconSize));
      children.add(const SizedBox(width: Spacing.s2));
    }

    children.add(
      Flexible(
        child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );

    if (trailingIcon != null) {
      children.add(const SizedBox(width: Spacing.s2));
      children.add(Icon(trailingIcon, size: _iconSize));
    }

    return Row(
      key: const ValueKey('label'),
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
