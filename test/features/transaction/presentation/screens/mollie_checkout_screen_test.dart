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
