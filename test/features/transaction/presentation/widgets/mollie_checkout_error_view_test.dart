import 'package:deelmarkt/features/transaction/presentation/widgets/mollie_checkout_error_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('MollieCheckoutErrorView', () {
    testWidgets('renders without exception', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MollieCheckoutErrorView(onRetry: () {}, onCancel: () {}),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('has a Semantics node with liveRegion true', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MollieCheckoutErrorView(onRetry: () {}, onCancel: () {}),
      );

      final liveRegionNodes = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.liveRegion == true);
      expect(liveRegionNodes, isNotEmpty);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      var retryCalled = false;
      await pumpLocalizedWidget(
        tester,
        MollieCheckoutErrorView(
          onRetry: () => retryCalled = true,
          onCancel: () {},
        ),
      );

      // The retry button has leadingIcon ArrowClockwise — tap by key text 'action.retry'
      final retryButton = find.text('action.retry');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button is tapped', (tester) async {
      var cancelCalled = false;
      await pumpLocalizedWidget(
        tester,
        MollieCheckoutErrorView(
          onRetry: () {},
          onCancel: () => cancelCalled = true,
        ),
      );

      final cancelButton = find.text('action.cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MollieCheckoutErrorView(onRetry: () {}, onCancel: () {}),
        theme: ThemeData.dark(),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
