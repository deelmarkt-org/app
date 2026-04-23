import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Responsive body wrapper that constrains content for larger screens.
///
/// - compact (<600px): full-width with mobile margins (16px)
/// - medium (600–840px): full-width with tablet margins (24px)
/// - expanded (≥840px): centered, max-width [maxWidth]
///
/// Pick the constructor by screen class:
/// - **Default [ResponsiveBody] (maxWidth 600)** — single-column flows:
///   auth / onboarding / forms / settings / appeal / review. Caps content
///   at a readable column width on desktop.
/// - **[ResponsiveBody.wide] (maxWidth 1200)** — multi-column dashboards:
///   home, search results, favourites, category browse. Caps content at
///   `Breakpoints.large` so grid cards keep reasonable proportions and
///   don't stretch edge-to-edge on ultra-wide viewports.
///
/// Reference: docs/design-system/tokens.md §Breakpoints
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({required this.child, this.maxWidth = 600, super.key})
    : assert(maxWidth > 0, 'ResponsiveBody.maxWidth must be > 0');

  /// Dashboard-style cap for grid/catalogue screens. Defaults to
  /// [Breakpoints.large] (1200px) per tokens.md §Breakpoints.
  const ResponsiveBody.wide({
    required this.child,
    this.maxWidth = Breakpoints.large,
    super.key,
  }) : assert(maxWidth > 0, 'ResponsiveBody.maxWidth must be > 0');

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
