import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/mollie_checkout_loading_overlay.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CircularProgressIndicator.adaptive() runs an infinite animation loop —
// pumpAndSettle would time out. Pump a single frame instead.
Future<void> _pump(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: theme ?? DeelmarktTheme.light,
        home: const Scaffold(body: MollieCheckoutLoadingOverlay()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('MollieCheckoutLoadingOverlay', () {
    testWidgets('renders without exception', (tester) async {
      await _pump(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains a CircularProgressIndicator', (tester) async {
      await _pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has a Semantics node with liveRegion true', (tester) async {
      await _pump(tester);

      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.liveRegion, isTrue);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await _pump(tester, theme: ThemeData.dark());
      expect(tester.takeException(), isNull);
    });
  });
}
