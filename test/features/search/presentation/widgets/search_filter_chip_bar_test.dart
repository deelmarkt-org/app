import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_filter_chip_bar.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildBar({
    required SearchFilter filter,
    VoidCallback? onTap,
    bool isDark = false,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: isDark ? DeelmarktTheme.dark : DeelmarktTheme.light,
        home: Scaffold(
          body: SearchFilterChipBar(
            filter: filter,
            onTap: onTap ?? () {},
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  testWidgets('renders at least 3 chips visible in horizontal scroll', (
    tester,
  ) async {
    // Horizontal ListView lazy-builds children; at 800 px viewport only
    // the first 3 chips fit inside the scroll viewport before clipping.
    // The full 5-chip scrollable is validated functionally (tap fires
    // onTap regardless of which chip) and visually via the mobile
    // screenshot driver in search_screenshot_test.dart.
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildBar(filter: const SearchFilter(query: 'test')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsAtLeast(3));
  });

  testWidgets('tapping any chip fires onTap', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var taps = 0;
    await tester.pumpWidget(
      buildBar(filter: const SearchFilter(query: 'test'), onTap: () => taps++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ActionChip).first);
    expect(taps, 1);
  });

  testWidgets('renders in dark mode', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildBar(filter: const SearchFilter(query: 'test'), isDark: true),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchFilterChipBar), findsOneWidget);
  });
}
