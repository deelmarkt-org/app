import 'package:flutter/widgets.dart';

/// Standardised animation tokens for DeelMarkt.
///
/// Tier-1 Audit L-05: Centralises animation durations and curves that were
/// previously hardcoded per-widget (300ms easeOutCubic in onboarding,
/// 200ms easeOutCubic in dots, etc.).
///
/// All widgets MUST check [MediaQuery.disableAnimations] and use
/// [Duration.zero] when reduced motion is enabled (WCAG 2.2 / EAA).
///
/// Usage:
/// ```dart
/// final reduceMotion = MediaQuery.of(context).disableAnimations;
/// AnimatedContainer(
///   duration: reduceMotion ? Duration.zero : DeelmarktAnimation.standard,
///   curve: DeelmarktAnimation.curveStandard,
///   ...
/// );
/// ```
abstract final class DeelmarktAnimation {
  // ---------------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------------

  /// Quick feedback (dot indicators, toggle states, opacity fades).
  /// 150ms — fast enough to feel instant, slow enough to register.
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard transitions (page slides, card reveals, layout shifts).
  /// 200ms — the default for most UI motion (tokens.md §Animation).
  static const Duration standard = Duration(milliseconds: 200);

  /// Emphasis/celebratory (success animations, onboarding transitions).
  /// 500ms — deliberate pace for moments worth noticing.
  static const Duration emphasis = Duration(milliseconds: 500);

  /// Shimmer loading sweep cycle.
  /// 1500ms — slow enough to be non-distracting on loading states.
  static const Duration shimmer = Duration(milliseconds: 1500);

  // ---------------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------------

  /// Standard easing for most transitions.
  static const Curve curveStandard = Curves.easeOutCubic;

  /// Entrance easing (elements appearing on screen).
  static const Curve curveEntrance = Curves.easeOut;

  /// Exit easing (elements leaving the screen).
  static const Curve curveExit = Curves.easeIn;

  /// Bounce/spring for celebratory moments (sparingly).
  static const Curve curveBounce = Curves.elasticOut;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns [Duration.zero] when reduced motion is enabled, otherwise [duration].
  /// Convenience helper so every call site doesn't need the ternary.
  static Duration resolve(Duration duration, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : duration;
}
