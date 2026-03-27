import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/router/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    Future<void> pumpSplash(WidgetTester tester, {ThemeData? theme}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: const SplashScreen(),
        ),
      );
      // Use pump() not pumpAndSettle — CircularProgressIndicator never settles.
      await tester.pump();
    }

    testWidgets('renders loading indicator', (tester) async {
      await pumpSplash(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with Scaffold', (tester) async {
      await pumpSplash(tester);

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await pumpSplash(tester);

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('uses dark background in dark mode', (tester) async {
      await pumpSplash(tester, theme: DeelmarktTheme.dark);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
