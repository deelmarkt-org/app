import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compute WCAG 2.0 contrast ratio between two opaque colors.
///
/// Uses Flutter's built-in [Color.computeLuminance] which implements
/// the WCAG relative luminance formula. Returns a value ≥ 1.0.
double computeContrastRatio(Color a, Color b) {
  assert(
    a.a == 1.0,
    'Color a must be opaque (alpha=${a.a}). '
    'Composite against background before computing contrast.',
  );
  assert(
    b.a == 1.0,
    'Color b must be opaque (alpha=${b.a}). '
    'Composite against background before computing contrast.',
  );

  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG 2.0 — Contrast ratio assertion (§1.4.3 text, §1.4.11 non-text).
///
/// Default [minRatio] is 4.5:1 for normal text. Use 3.0 for large text
/// or non-text UI components.
void expectContrastRatio({
  required Color foreground,
  required Color background,
  double minRatio = 4.5,
}) {
  final ratio = computeContrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minRatio),
    reason:
        'Contrast ratio ${ratio.toStringAsFixed(2)}:1 < '
        '$minRatio:1 minimum (WCAG 1.4.3)',
  );
}

/// Verify that a widget has the expected [Semantics] label.
void expectHasSemanticsLabel(
  WidgetTester tester,
  Finder finder,
  String expectedLabel,
) {
  final semantics = tester.getSemantics(finder);
  expect(
    semantics.label,
    expectedLabel,
    reason:
        'Semantics label "${semantics.label}" does not match '
        'expected "$expectedLabel"',
  );
}

/// Verify that reduced motion is respected — animation is disabled
/// when [MediaQuery.disableAnimations] is true.
///
/// Pumps [widget] with animations disabled, then verifies that no
/// animation controllers are actively running after settling.
Future<void> expectReducedMotionCompliant(
  WidgetTester tester,
  Widget widget,
  Finder animationFinder,
) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: widget,
    ),
  );
  // Allow one frame for the widget to read disableAnimations and stop.
  await tester.pump(const Duration(milliseconds: 100));

  // Widget should still render (not removed).
  expect(animationFinder, findsWidgets);

  // Verify no animations are actively running after settling.
  // tester.hasRunningAnimations checks all animation controllers.
  expect(
    tester.hasRunningAnimations,
    isFalse,
    reason:
        'Animations should not be running when '
        'MediaQuery.disableAnimations is true (WCAG 2.3.3)',
  );
}
