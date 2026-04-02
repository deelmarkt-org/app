import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Pump a widget wrapped in EasyLocalization + MaterialApp + Theme.
///
/// Use this when the widget under test calls `context.locale` (e.g.
/// ProfileHeader). Translations are NOT loaded — `.tr()` still returns
/// the key path — but the EasyLocalization ancestor is present so
/// `context.locale` does not throw.
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('nl');

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: theme ?? DeelmarktTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
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

/// Pump a full-screen widget with [ProviderScope] + [EasyLocalization].
///
/// Use when the screen (or its children) call `context.locale`.
Future<void> pumpLocalizedScreenWithProviders(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('nl');

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: MaterialApp(theme: theme ?? DeelmarktTheme.light, home: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
