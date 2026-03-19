import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/deel_button_theme.dart';
import '../../core/design_system/spacing.dart';
import 'deel_button_style.dart';
import 'deel_button_tokens.dart';

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
  final String? loadingLabel;

  /// Accessibility hint for destructive variant (caller provides l10n string).
  final String? semanticDestructiveHint;

  /// Optional icon before the label.
  final IconData? leadingIcon;

  /// Optional icon after the label.
  final IconData? trailingIcon;

  /// Whether the button expands to fill its parent width.
  final bool fullWidth;

  bool get _hasHaptic =>
      variant == DeelButtonVariant.primary ||
      variant == DeelButtonVariant.destructive ||
      variant == DeelButtonVariant.success;

  @override
  Widget build(BuildContext context) {
    final buttonTheme =
        Theme.of(context).extension<DeelButtonThemeData>() ??
        DeelButtonThemeData.light();
    final bool isDisabled = isLoading || onPressed == null;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    final styleResolver = DeelButtonStyleResolver(
      variant: variant,
      size: size,
      fullWidth: fullWidth,
      theme: buttonTheme,
    );
    final ButtonStyle style = styleResolver.resolve();
    final Widget child = _buildChild(reduceMotion, buttonTheme);

    final VoidCallback? effectiveOnPressed =
        isDisabled
            ? null
            : () {
              if (_hasHaptic) HapticFeedback.lightImpact();
              onPressed?.call();
            };

    return Semantics(
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
  }

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

  Widget _buildChild(bool reduceMotion, DeelButtonThemeData buttonTheme) {
    final iconSize = DeelButtonTokens.iconSizeFor(size);
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
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    buttonTheme.primaryForeground,
                  ),
                ),
              )
              : _buildLabelRow(iconSize),
    );
  }

  Widget _buildLabelRow(double iconSize) {
    final List<Widget> children = [];

    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: iconSize));
      children.add(const SizedBox(width: Spacing.s2));
    }

    children.add(
      Flexible(
        child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );

    if (trailingIcon != null) {
      children.add(const SizedBox(width: Spacing.s2));
      children.add(Icon(trailingIcon, size: iconSize));
    }

    return Row(
      key: const ValueKey('label'),
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
