import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/transaction/presentation/screens/mollie_checkout_screen.dart';

/// Contract tests for [MollieCheckoutScreen] — verifies the public API
/// (constructor + result enum) and trusted-host URL assertion. Full
/// widget-rendering tests are skipped because the screen instantiates a
/// real `WebViewController` in `initState` which requires platform
/// channel mocks; the actual payment flow is validated end-to-end by
/// Mollie's own sandbox.
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
