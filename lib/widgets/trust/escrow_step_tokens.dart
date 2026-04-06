/// Size and style constants for escrow step circles.
abstract final class EscrowStepTokens {
  static const double circleSize = 24;
  static const double innerDotSize = 8;
  static const double borderWidth = 2;
  static const double checkIconSize = 14;
  static const double connectorDashWidth = 4;
  static const double connectorDashGap = 3;
  static const double connectorHeight = 2;

  /// Minimum tappable area — WCAG 2.2 AA (44x44px).
  static const double minTapTarget = 44;

  /// Pulse animation duration for the active state (fix A8).
  static const Duration pulseDuration = Duration(milliseconds: 1200);

  /// Pulse animation scale range — 1.0 → 1.12 → 1.0.
  static const double pulseMaxScale = 1.12;

  /// Stepper row height at wide layouts (≥ 360 px).
  static const double rowHeightWide = 104;

  /// Stepper row height at narrow layouts (< 360 px) — extra space for the
  /// 2-line label wrap plus the deadline hint.
  static const double rowHeightNarrow = 120;

  /// Connector vertical offset so the line aligns with the middle of the
  /// circle, regardless of tap-target padding.
  static const double connectorTopOffset = (minTapTarget - connectorHeight) / 2;

  /// Step label font size at narrow layouts.
  static const double narrowLabelFontSize = 10;

  /// Deadline-hint font size + top padding.
  static const double deadlineHintFontSize = 10;
  static const double deadlineHintTopPadding = 2;
}

/// Visual tone for an [EscrowStepCircle].
///
/// Drives colour selection so the widget stays theme- and state-aware
/// without hard-coding brand tokens for every branch (fix A3).
enum EscrowStepTone { trust, warning, muted }
