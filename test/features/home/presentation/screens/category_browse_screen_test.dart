import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/screens/category_browse_screen.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_card.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget buildTestWidget() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [useMockDataProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const CategoryBrowseScreen(),
        ),
      ),
    );
  }

  group('CategoryBrowseScreen', () {
    testWidgets('renders loading skeleton initially', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      // Pump one frame to trigger build — data is still loading
      await tester.pump();

      expect(find.byType(SkeletonBox), findsWidgets);

      // Let timers complete to avoid pending-timer assertion
      await tester.pumpAndSettle();
    });

    testWidgets('after data loads, shows 8 CategoryCard widgets', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CategoryCard), findsNWidgets(8));
    });

    testWidgets('shows category names after loading', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Elektronica'), findsOneWidget);
      expect(find.text('Voertuigen'), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator for pull-to-refresh', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
