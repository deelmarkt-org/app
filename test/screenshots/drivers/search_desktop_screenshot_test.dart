/// Screenshot driver — Search results screen on desktop.
///
/// Captures the master-detail layout introduced in #193 PR C: 240-px filter
/// sidebar (`Breakpoints.filterSidebarWidth`) on the left, results grid on
/// the right. Matches `docs/screens/02-home/designs/search_desktop_results_sidebar`.
///
/// Mobile coverage stays in `search_screenshot_test.dart` (horizontal chip
/// bar + bottom-sheet flow). This driver only fires on the
/// `desktop_1400` frame from `kScreenshotDesktopDevices`.
///
/// ### Why this driver could not ship in PR #210
///
/// `AdaptiveListingGrid` previously read `MediaQuery.sizeOf` (viewport
/// width) and returned 5 cols inside the 1159-px results pane (1400 viewport
/// minus 240-px sidebar minus 1-px divider) — `DeelCard` then overflowed
/// vertically by ~16 px. PR #213 made the grid container-aware via
/// `SliverLayoutBuilder` + `Breakpoints.gridColumnsForContainerWidth`, so
/// the pane now correctly resolves to 4 cols and the screen captures
/// without overflow. This driver is the regression pin for that fix.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203) — the search results grid watches an
/// `AsyncNotifier` chain and falls into the same class as the other
/// affected surfaces. Reintroduce
/// `for (final theme in ScreenshotTheme.values)` once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/search/presentation/search_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('search_desktop ${device.id} $locale light', (tester) async {
        await captureScreenshot(
          tester: tester,
          // Seed an initial query so the results grid + sidebar render
          // instead of the initial recent-searches view. "fiets" returns
          // results in both NL and EN mock data.
          screen: const SearchScreen(initialQuery: 'fiets'),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'search_desktop',
        );
      });
    }
  }
}
