/// Screenshot driver — Category browse screen on desktop.
///
/// Captures the 2-column grid layout introduced in #193 PR B. Exercises
/// the desktop 1400×900 frame to match
/// `docs/screens/02-home/designs/category_browse_desktop_light`.
///
/// Mobile + tablet coverage stays in the existing
/// `category_browse_screenshot_test.dart`. That driver's `android_tablet`
/// (800 px wide) still renders the vertical list (below the 840-px
/// breakpoint). `ios_ipad_129` (1024 px) now crosses the breakpoint and
/// will regenerate to the 2-col grid — that change is intentional and
/// matches the spec's §Expanded variant.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). `CategoryBrowseScreen` does not chain
/// `Future.wait` in its notifier, but to stay consistent with the other
/// #193 desktop drivers (`home_buyer_desktop`, `favourites_desktop`,
/// `category_detail_desktop`) we ship light-only here too and
/// reintroduce dark variants once #203 lands and the convention
/// normalises.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/presentation/screens/category_browse_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('category_browse_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const CategoryBrowseScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'category_browse_desktop',
        );
      });
    }
  }
}
