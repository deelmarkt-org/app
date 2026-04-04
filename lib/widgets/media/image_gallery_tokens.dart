/// Dimension constants for [ImageGallery] and [ImageGalleryFullscreen].
///
/// Reference: docs/design-system/components.md §ImageGallery
/// Reference: docs/design-system/patterns.md §Listing Detail
abstract final class ImageGalleryTokens {
  // ── Layout ──────────────────────────────────────────────────────────

  /// Default aspect ratio (4:3) per design spec.
  static const double defaultAspectRatio = 4 / 3;

  /// Max images per listing (E01 spec) — defensive cap on display.
  static const int maxImages = 12;

  // ── Dot indicators ──────────────────────────────────────────────────

  static const double dotActiveSize = 8;
  static const double dotInactiveSize = 6;
  static const double dotSpacing = 3;
  static const double dotsBottomOffset = 12;

  // ── Counter pill (e.g. "1 / 8") ─────────────────────────────────────

  static const double counterPillHeight = 28;
  static const double counterPillPaddingH = 10;
  static const double counterPillPaddingV = 6;
  static const double counterFontSize = 12;
  static const double counterBottomOffset = 12;
  static const double counterRightOffset = 12;
  static const double counterOpacity = 0.7;

  // ── Fullscreen zoom ─────────────────────────────────────────────────

  static const double fullscreenMinScale = 1.0;
  static const double fullscreenMaxScale = 4.0;
  static const double fullscreenDoubleTapScale = 2.0;

  /// Vertical drag distance (px) to dismiss fullscreen.
  static const double dragDismissThreshold = 120;

  /// Divisor for computing opacity from drag offset. A drag of this many
  /// pixels reduces opacity by 1.0 (before clamping to [dragOpacityFloor]).
  static const double dragOpacityDivisor = 400;

  /// Minimum opacity during drag-to-dismiss (lower bound of the clamp).
  static const double dragOpacityFloor = 0.3;

  // ── Close button positioning ────────────────────────────────────────

  static const double closeButtonTopOffset = 8;
  static const double closeButtonRightOffset = 8;
}
