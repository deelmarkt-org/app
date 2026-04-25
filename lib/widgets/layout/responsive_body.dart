import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Responsive body wrapper that constrains content for larger screens.
///
/// - compact (<600px): full-width
/// - medium (600–840px): full-width
/// - expanded (≥840px): centered, max-width [maxWidth]
///
/// Horizontal padding is applied *inside* the [maxWidth] cap when
/// [addHorizontalPadding] is `true`: [Spacing.screenMarginMobile] (16) on
/// compact and [Spacing.screenMarginTablet] (24) on medium+.
///
/// Pick the constructor by screen class:
///
/// - **Default [ResponsiveBody] (maxWidth [Breakpoints.formMaxWidth] = 600,
///   padding on)** — single-column flows: auth / onboarding / forms /
///   settings / appeal / review. The wrapper owns the horizontal screen
///   margin so callers pass a plain child.
/// - **[ResponsiveBody.wide] (maxWidth 1200, padding OFF)** — multi-column
///   dashboards: home, search results, favourites, category browse, listing
///   detail. Children are typically sliver trees (`CustomScrollView`) whose
///   individual slivers (`AdaptiveListingGrid`, section headers, cards) own
///   their own horizontal padding. Adding outer padding would double the
///   margin and misalign cards relative to their headers, so the `.wide()`
///   variant defaults to `addHorizontalPadding: false`. Pass `true`
///   explicitly if the child does NOT manage its own horizontal margins.
///
/// Reference: docs/design-system/tokens.md §Breakpoints.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    required this.child,
    this.maxWidth = Breakpoints.formMaxWidth,
    this.addHorizontalPadding = true,
    super.key,
  }) : assert(maxWidth > 0, 'ResponsiveBody.maxWidth must be > 0');

  /// Dashboard-style cap for grid/catalogue screens. Defaults to
  /// [Breakpoints.large] (1200px) per tokens.md §Breakpoints and **turns off
  /// the wrapper's horizontal padding** because sliver-based dashboards own
  /// their own margins. See class-level dartdoc for the rationale.
  const ResponsiveBody.wide({
    required this.child,
    this.maxWidth = Breakpoints.large,
    this.addHorizontalPadding = false,
    super.key,
  }) : assert(maxWidth > 0, 'ResponsiveBody.maxWidth must be > 0');

  final Widget child;

  /// Max content width on expanded/large screens.
  final double maxWidth;

  /// When `true` (the default form-column behaviour), the wrapper adds an
  /// inner `Padding` of [Spacing.screenMarginMobile] / [Spacing.screenMarginTablet]
  /// to provide the screen margin. When `false`, the caller (usually a
  /// sliver tree) is responsible for its own horizontal padding.
  final bool addHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final capped = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: addHorizontalPadding ? _padded(context, child) : child,
    );
    return Center(child: capped);
  }

  Widget _padded(BuildContext context, Widget inner) {
    final padding =
        Breakpoints.isCompact(context)
            ? Spacing.screenMarginMobile
            : Spacing.screenMarginTablet;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: inner,
    );
  }
}
