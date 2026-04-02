import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';

/// A 44×44px circular icon button with a semi-transparent surface background.
///
/// Meets WCAG touch target requirements (≥ 44×44px).
/// Includes [Semantics] with `button: true` and a mandatory [label].
///
/// Used in image overlays (gallery, maps) and other contexts requiring
/// a floating action button on top of media content.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? iconColor;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              icon,
              color:
                  iconColor ??
                  (isDark
                      ? DeelmarktColors.darkOnSurface
                      : DeelmarktColors.neutral700),
              size: DeelmarktIconSize.sm,
            ),
          ),
        ),
      ),
    );
  }
}
