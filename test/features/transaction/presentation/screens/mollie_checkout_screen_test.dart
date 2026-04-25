import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/transaction/presentation/screens/mollie_checkout_screen.dart';

/// Tests for Mollie checkout presentation layer:
/// - `MollieCheckoutResult` enum contract (two values).
/// - `MollieCheckoutScreen` constructor contract (required params).
/// - `MollieCheckoutBodyFrame` layout contract (500px cap on desktop;
///   child fills native width below the cap on mobile) — exercised as
///   a standalone widget so the cap is regression-pinned without mounting
///   the parent screen, which instantiates a real [WebViewController]
///   in `initState` (unavailable in `flutter test`).
///
/// The trusted-host URL `assert(...)` in `initState` is NOT unit-tested —
/// it fires only when the screen is mounted, and the mount path is
/// blocked by the same platform-channel constraint above. End-to-end
/// coverage comes from Mollie's sandbox.
void main() {
  group('MollieCheckoutResult', () {
    test('has exactly two values (completed, cancelled)', () {
      expect(MollieCheckoutResult.values, hasLength(2));
      expect(
        MollieCheckoutResult.values,
        containsAll([
          MollieCheckoutResult.completed,
          MollieCheckoutResult.cancelled,
        ]),
      );
    });
  });

  group('MollieCheckoutBodyFrame', () {
    testWidgets('caps child width at 500px on desktop viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MollieCheckoutBodyFrame(child: SizedBox.expand()),
          ),
        ),
      );

      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(MollieCheckoutBodyFrame),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 500);
    });

    testWidgets('lets child fill width below 500px on mobile viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MollieCheckoutBodyFrame(
              child: SizedBox(key: Key('child'), width: double.infinity),
            ),
          ),
        ),
      );

      // Child renders at viewport width (400) because the cap is above it.
      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, 400);
    });
  });

  group('MollieCheckoutScreen constructor', () {
    test('accepts valid Mollie checkout URL + redirect URL', () {
      expect(
        () => const MollieCheckoutScreen(
          checkoutUrl: 'https://www.mollie.com/checkout/select-method/x',
          redirectUrl: 'https://app.deelmarkt.com/checkout/complete',
        ),
        returnsNormally,
      );
    });

    test('requires both checkoutUrl and redirectUrl parameters', () {
      // Compile-time guarantee — constructor has both as `required`.
      // This test documents the contract for future maintainers.
      const screen = MollieCheckoutScreen(
        checkoutUrl: 'https://www.mollie.com/',
        redirectUrl: 'https://app.deelmarkt.com/',
      );
      expect(screen.checkoutUrl, isNotEmpty);
      expect(screen.redirectUrl, isNotEmpty);
    });
  });
}
