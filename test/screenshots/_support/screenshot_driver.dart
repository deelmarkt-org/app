/// Screenshot driver — pumps any screen with:
///  • mock repositories (USE_MOCK_DATA=true semantics via ProviderScope)
///  • EasyLocalization wired up for NL or EN
///  • DeelmarktTheme light or dark
///  • MediaQuery sized to the target DeviceFrame
///  • Animations disabled (stable golden frames)
///
/// Usage:
/// ```dart
/// await screenshotDriver(
///   tester: tester,
///   screen: const HomeScreen(),
///   locale: 'nl_NL',
///   theme: ScreenshotTheme.light,
///   device: kScreenshotDevices.first,
///   goldenName: 'home_buyer',
/// );
/// ```
library;

import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';

import '../../helpers/tolerant_golden_comparator.dart';
import 'device_frames.dart';
import 'seed_data.dart';

// Flutter's pumpAndSettle timeout message — stable since Flutter 2.x.
// Extracted so a single place needs updating if Flutter ever changes the wording.
const _kPumpAndSettleTimeoutMsg = 'pumpAndSettle timed out';

/// One-time async setup — call in `setUpAll` of each screenshot test group.
Future<void> initScreenshotEnvironment() async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('nl');

  // Screenshot drivers compare pixel-for-pixel via `matchesGoldenFile`. Sub-
  // pixel font-hinting differences between CI's macos-14 runner and developer
  // machines (even both macOS) produce ≤0.5% diffs that trip Flutter's default
  // strict [LocalFileComparator]. Wire in the tolerant comparator already used
  // by widget goldens (photo_grid_tile_golden_test.dart, responsive_detail_*)
  // so the same 0.5% tolerance applies to screen-level goldens. Any path in
  // `test/screenshots/drivers/` resolves to the correct basedir because all
  // drivers share a single `goldens/` subdirectory.
  goldenFileComparator = TolerantGoldenFileComparator.forTestFile(
    'test/screenshots/drivers/shipping_qr_screenshot_test.dart',
  );
}

/// Pump [screen] in screenshot mode and capture a golden file.
///
/// The golden file is written to
/// `test/screenshots/drivers/goldens/<goldenName>_<locale>_<theme>_<device.id>.png`
/// when running with `flutter test --update-goldens`.
Future<void> captureScreenshot({
  required WidgetTester tester,
  required Widget screen,
  required String locale,
  required ScreenshotTheme theme,
  required DeviceFrame device,
  required String goldenName,
  List<Override> extraOverrides = const [],
}) async {
  // Suppress network image errors — screenshot tests run headless with no
  // network access. Avatar / thumbnail URLs will fail silently; the widget
  // renders its error/fallback state instead, which is fine for goldens.
  final savedOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('NetworkImageLoadException') ||
        msg.contains('HTTP request failed') ||
        msg.contains('SocketException')) {
      return;
    }
    savedOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = savedOnError);

  // Evict l10n asset files from Flutter's rootBundle cache so EasyLocalization
  // always sends a fresh platform-channel request (rather than returning a
  // synchronous Future.value from cache). When a cached locale is returned
  // synchronously, the EasyLocalization rebuild that makes the child screen
  // visible happens inside pumpWidget's microtask queue — taking a different
  // code path that does not produce the expected "second build" within
  // pumpAndSettle. Evicting the cache keeps the async path consistent across
  // test orderings and fixes the loaded-state race for issue #203.
  //
  // Keys must use hyphens: RootBundleAssetLoader calls
  // locale.toStringWithSeparator(separator: "-"), producing "nl-NL.json" /
  // "en-US.json". The rootBundle cache is keyed by exact path string, so
  // underscore-separated paths (nl_NL.json) are a cache miss for the eviction
  // and leave the warm entry untouched — causing canary failures after the 24
  // loop tests prime the cache. Fix for P-54 PR-A1.
  for (final tag in kScreenshotLocales) {
    rootBundle.evict('assets/l10n/${tag.replaceAll('_', '-')}.json');
  }

  // Set the surface to the target device size.
  await tester.binding.setSurfaceSize(device.logicalSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // Commit the resize to the render tree BEFORE building the widget tree.
  // setSurfaceSize calls handleMetricsChanged() which marks the render view
  // for layout, but the layout pass is still pending. Without this pump,
  // the subsequent pumpWidget attaches the new tree before the view geometry
  // has been committed, and subsequent testWidgets iterations within the same
  // driver paint to a stale (null/prior) surface — producing fully transparent
  // canvases. One pump flushes the pending layout so pumpWidget starts clean.
  // Fix for issue #203 (test-isolation defect between driver iterations).
  await tester.pump();

  final localeObj = _parseLocale(locale);
  final themeData =
      theme == ScreenshotTheme.light
          ? DeelmarktTheme.light
          : DeelmarktTheme.dark;
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...extraOverrides,
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        startLocale: localeObj,
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: Builder(
          builder:
              // ValueKey scoped to locale+theme+device forces a fresh
              // MaterialApp element when the test configuration changes.
              // Flutter's Localizations widget caches loaded delegates; a
              // fresh element has an empty _resources map so _load() always
              // triggers the rebuild. A stable key (vs UniqueKey) avoids
              // discarding and recreating the subtree on every setState within
              // a single captureScreenshot call. Fix for issue #203.
              (ctx) => MaterialApp(
                key: ValueKey('screenshot-$locale-${theme.name}-${device.id}'),
                locale: EasyLocalization.of(ctx)?.locale,
                localizationsDelegates: EasyLocalization.of(ctx)?.delegates,
                supportedLocales:
                    EasyLocalization.of(ctx)?.supportedLocales ??
                    const [Locale('en', 'US')],
                theme: themeData,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: device.logicalSize,
                    devicePixelRatio: device.devicePixelRatio,
                    disableAnimations: true,
                    // MediaQueryData() defaults all insets to EdgeInsets.zero,
                    // so safe-area / keyboard insets don't clip headless goldens.
                  ),
                  // Scaffold wrapper ensures the screen has a material
                  // surface with resizeToAvoidBottomInset=false so the
                  // screen body is not clipped by the test viewport.
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: screen,
                  ),
                ),
              ),
        ),
      ),
    ),
  );

  // EasyLocalization's locale loading uses two different async completion paths:
  //
  //   A. First load: rootBundle.loadString() sends a platform-channel message.
  //      The response is delivered as a platform callback during a pump() call.
  //
  //   B. Subsequent loads of the same locale: rootBundle's Dart-side cache
  //      returns Future.value(cachedData), which schedules a microtask.
  //      Inside fakeAsync, microtasks are only flushed during elapse() — NOT
  //      during pump() (which skips elapse when no duration is given).
  //      pump(Duration.zero) calls fakeAsync.elapse(Duration.zero), which DOES
  //      flush the microtask queue, firing the Future.value callback so
  //      EasyLocalization calls setState and schedules its second build.
  //
  // Sequence:
  //   pump(Duration.zero) → flush microtasks → EasyLocalization setState
  //   pump()              → render second build → ChatThreadScreen mounts →
  //                         AsyncNotifier schedules Future.delayed timers
  //   pump(600ms)         → fire mock-repo timers → notifier resolves
  //
  // Fix for issue #203 (async-resolution half — both load paths).
  await tester.pump(Duration.zero); // flush fakeAsync microtask queue
  await tester.pump(); // render EasyLocalization's second build

  // Advance the fake clock to fire mock-repo Future.delayed timers (200–400ms).
  await tester.pump(const Duration(milliseconds: 600));

  // Drain any remaining animated frames after the notifier resolves.
  // Shimmer's AnimationController.repeat() creates an infinite ticker that
  // prevents pumpAndSettle from ever completing even with disableAnimations,
  // so we use a bounded timeout and fall back to fixed pumps.
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(milliseconds: 800),
    );
  } on FlutterError catch (e) {
    if (!e.message.contains(_kPumpAndSettleTimeoutMsg)) rethrow;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  final themeId = theme == ScreenshotTheme.light ? 'light' : 'dark';
  final goldenPath =
      'goldens/${goldenName}_${locale}_${themeId}_${device.id}.png';

  // Golden pixel comparison is macOS-only: goldens are generated on macos-14
  // (arm64) by screenshots.yml. Linux/Windows CI renders fonts differently
  // and would produce false positives — it still pumps the widget
  // above for coverage, but skips the pixel assertion.
  // Gemini MED (screenshot_driver.dart:136): animation-aware pump added above.
  if (!Platform.isMacOS) {
    // Advance the fake timer clock past any pending dart:async Timer deadlines.
    // EasyLocalization schedules a zero-duration Timer on first locale load;
    // without this drain, the test framework reports "A Timer is still pending"
    // when the widget tree is disposed after the test body returns.
    await tester.pump(const Duration(seconds: 30));
    return;
  }

  await expectLater(find.byType(MaterialApp), matchesGoldenFile(goldenPath));

  // Drain any timers that are still pending after the golden capture.
  // MockRepository Future.delayed(200ms) timers may still be tracked by
  // fake_async after pumpWidget replaces the tree; without this drain the
  // test framework reports "A Timer is still pending" on the first device
  // variant of each locale (before the fake-clock has advanced past them).
  await tester.pump(const Duration(seconds: 30));
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Locale _parseLocale(String tag) {
  final parts = tag.split('_');
  return parts.length >= 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}
