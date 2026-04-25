import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';

/// Adaptive master-detail scaffold.
///
/// - Below [breakpoint] (default 840px): renders [detail] if non-null,
///   otherwise [master]. Caller drives navigation between them (e.g.
///   pushing a route for the detail on mobile).
/// - At or above [breakpoint]: renders a `Row` with [master] on the left
///   (fixed [masterWidth]) and [detail] expanding on the right. When
///   [detail] is null, [emptyDetail] is shown (or a blank panel).
///
/// `Row` uses `CrossAxisAlignment.stretch` so scrollable children
/// (`ListView`, `CustomScrollView`) fill the viewport vertically and the
/// `VerticalDivider` gets a non-zero height. Without `stretch`, `Row`'s
/// default `center` alignment leaves scrollables with intrinsic-height
/// constraints they can't resolve and the divider collapses to 0px.
///
/// Defaults ([masterWidth] = 360, [breakpoint] = [Breakpoints.medium]) match
/// `MessagesResponsiveShell` so #194 can drop-in migrate without behaviour
/// change. Treat these values as the design-system contract for any future
/// master-detail surface.
///
/// Reference: docs/design-system/tokens.md §Breakpoints — "Adaptive patterns"
/// (Listing detail, Chat, Filters use the split-view pattern above medium).
class ResponsiveDetailScaffold extends StatelessWidget {
  const ResponsiveDetailScaffold({
    required this.master,
    this.detail,
    this.emptyDetail,
    this.masterWidth = 360,
    this.breakpoint = Breakpoints.medium,
    this.dividerColor,
    super.key,
  });

  final Widget master;
  final Widget? detail;
  final Widget? emptyDetail;
  final double masterWidth;
  final double breakpoint;

  /// Optional override for the divider color. When null, the divider uses
  /// [DividerThemeData.color] from the app theme. Screens with their own
  /// palette semantics (e.g. messages chat-theme `border` token, which
  /// diverges from the generic dark divider on a ~3% luminance shift) can
  /// pass a token-specific color here to keep parity with the rest of the
  /// feature.
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpoint) {
      return detail ?? master;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: masterWidth, child: master),
        VerticalDivider(thickness: 1, width: 1, color: dividerColor),
        Expanded(child: detail ?? emptyDetail ?? const SizedBox.shrink()),
      ],
    );
  }
}
