import 'package:flutter/material.dart';

/// DeelMarkt responsive breakpoints.
/// Reference: docs/design-system/tokens.md §Breakpoints
class Breakpoints {
  Breakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  /// Alias for [expanded] (1200px) — the lower bound of the "large" tier
  /// that [isLarge] checks. Kept in sync with tokens.md §Breakpoints so
  /// call sites can read `Breakpoints.large` alongside the `isLarge`
  /// predicate without chasing two names for the same value.
  static const double large = expanded;

  /// Max content width for single-column layouts (onboarding, auth forms).
  static const double contentMaxWidth = 500;

  /// Max width of the auth/gate card surface (login, register, suspension
  /// gate). Matches the expanded-viewport card width specified in
  /// `docs/screens/01-auth/02-registration.md` §Expanded,
  /// `03-login.md`, and `06-suspension-gate.md`.
  static const double authCardMaxWidth = 480;

  /// Max width for single-column forms (review, review result, generic
  /// [ResponsiveBody] default). Kept in sync with `ResponsiveBody`'s
  /// default so there is one canonical form-column width.
  static const double formMaxWidth = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact &&
      MediaQuery.sizeOf(context).width < medium;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;

  /// `true` when width ≥ [large] (1200px) — desktop-class viewports that
  /// benefit from denser grids, persistent sidebars, and wider content caps.
  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= large;

  /// Listing-grid column count for the current viewport.
  /// Reference: docs/design-system/tokens.md §Breakpoints (2 / 3 / 4 / 5).
  static int gridColumnsForWidth(BuildContext context) {
    if (isCompact(context)) return 2;
    if (isMedium(context)) return 3;
    if (isLarge(context)) return 5;
    return 4;
  }
}
