import 'package:flutter/material.dart';

/// DeelMarkt responsive breakpoints.
/// Reference: docs/design-system/tokens.md §Breakpoints
class Breakpoints {
  Breakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  /// Max content width for single-column layouts (onboarding, auth forms).
  static const double contentMaxWidth = 500;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact &&
      MediaQuery.sizeOf(context).width < medium;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;

  /// `true` when width ≥ `expanded` (1200px) — desktop-class viewports that
  /// benefit from denser grids, persistent sidebars, and wider content caps.
  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// Listing-grid column count for the current viewport.
  /// Reference: docs/design-system/tokens.md §Breakpoints (2 / 3 / 4 / 5).
  static int gridColumnsForWidth(BuildContext context) {
    if (isCompact(context)) return 2;
    if (isMedium(context)) return 3;
    if (isLarge(context)) return 5;
    return 4;
  }
}
