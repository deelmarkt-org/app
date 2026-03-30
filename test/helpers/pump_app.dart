import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Pump a widget wrapped in MaterialApp + Theme for widget tests.
///
/// Does NOT use EasyLocalization — `.tr()` calls return the key path
/// in tests, which is sufficient for verifying widget structure.
/// This avoids async translation loading issues in test environments.
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pump a full-screen widget (one that contains its own Scaffold).
Future<void> pumpTestScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(theme: theme ?? DeelmarktTheme.light, home: screen),
  );
  await tester.pumpAndSettle();
}

/// Pump a full-screen widget wrapped in [ProviderScope] for Riverpod tests.
///
/// Use [overrides] to inject test dependencies (e.g. SharedPreferences).
Future<void> pumpTestScreenWithProviders(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: theme ?? DeelmarktTheme.light, home: screen),
    ),
  );
  await tester.pumpAndSettle();
}
