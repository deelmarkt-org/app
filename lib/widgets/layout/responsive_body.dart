import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Responsive body wrapper that constrains content for larger screens.
///
/// - compact (<600px): full-width with mobile margins (16px)
/// - medium (600–840px): full-width with tablet margins (24px)
/// - expanded (>840px): centered, max-width 600px
///
/// Reference: docs/design-system/tokens.md §Breakpoints
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({required this.child, this.maxWidth = 600, super.key});

  final Widget child;

  /// Max content width on expanded/large screens.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding =
        Breakpoints.isCompact(context)
            ? Spacing.screenMarginMobile
            : Spacing.screenMarginTablet;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: child,
        ),
      ),
    );
  }
}
