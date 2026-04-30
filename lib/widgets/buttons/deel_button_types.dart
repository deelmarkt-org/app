/// Shared enum types for [DeelButton].
///
/// Extracted from `deel_button.dart` to keep the main button widget file
/// ≤200 LOC per CLAUDE.md §2.1. Re-exported by `deel_button.dart`, so all
/// existing call sites keep working without an import change.
///
/// Reference: docs/design-system/components.md §Buttons
library;

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
