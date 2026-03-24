import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.2 AA — Touch target size verification (§2.5.8).
///
/// Asserts that the widget found by [finder] meets the minimum
/// touch target dimensions. Default minimum is 44×44px per WCAG and
/// European Accessibility Act requirements.
void expectMeetsMinTouchTarget(
  WidgetTester tester,
  Finder finder, {
  double minSize = 44.0,
}) {
  final size = tester.getSize(finder);
  expect(
    size.width,
    greaterThanOrEqualTo(minSize),
    reason:
        'Touch target width ${size.width}px < ${minSize}px minimum '
        '(WCAG 2.5.8)',
  );
  expect(
    size.height,
    greaterThanOrEqualTo(minSize),
    reason:
        'Touch target height ${size.height}px < ${minSize}px minimum '
        '(WCAG 2.5.8)',
  );
}

/// WCAG 2.2 AA — Target spacing verification (§2.5.8).
///
/// Asserts that the gap between two interactive elements meets the
/// minimum spacing requirement. Default minimum is 8px.
void expectTargetSpacing(
  WidgetTester tester,
  Finder a,
  Finder b, {
  double minSpacing = 8.0,
}) {
  final rectA = tester.getRect(a);
  final rectB = tester.getRect(b);

  final horizontalGap = (rectB.left - rectA.right).abs();
  final verticalGap = (rectB.top - rectA.bottom).abs();
  final gap = horizontalGap < verticalGap ? horizontalGap : verticalGap;

  expect(
    gap,
    greaterThanOrEqualTo(minSpacing),
    reason: 'Target spacing ${gap}px < ${minSpacing}px minimum (WCAG 2.5.8)',
  );
}
