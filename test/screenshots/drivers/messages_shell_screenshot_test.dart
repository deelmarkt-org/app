/// Screenshot driver — Messages master-detail shell on desktop (empty state).
///
/// Captures the DESKTOP "no conversation selected" layout introduced in
/// #194, matching `docs/screens/06-chat/designs/messages_desktop_expanded.png`
/// (list + "pick a conversation" empty state).
///
/// Mobile messages UX is already covered by the standalone
/// `chat_thread_screenshot_test.dart` driver — we only need the desktop
/// empty state here.
///
/// ### Scope — light theme only, for now
///
/// Thread-state goldens and dark-theme empty-state goldens both trip the
/// pre-existing `captureScreenshot` capture bug where screens whose async
/// `build()` chains `Future.wait` + a realtime stream produce solid-color
/// output (widget tree populates — `find.text` verifies — but
/// `matchesGoldenFile` captures a pre-paint frame). Evidence: in dev,
/// `chat_thread_en_US_light_android_phone` and `chat_thread_en_US_dark_android_phone`
/// share blob `492a7ff0`, which is physically impossible for a correctly
/// rendered theme-sensitive surface. Fixing the capture path is out of
/// #194 scope — tracked in **#203**.
///
/// Light-theme empty state renders cleanly because `NoThreadSelected` has
/// no async dependency and the list's loading-state shimmer on light
/// backgrounds produces varied pixel output. We keep those 2 goldens;
/// reintroduce dark + thread variants once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/presentation/screens/messages_responsive_shell.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens are deliberately omitted per #203 — see library
  // docstring. Reintroduce `for (final theme in ScreenshotTheme.values)`
  // once the capture-infra fix lands.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('messages_shell_empty ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const MessagesResponsiveShell(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'messages_shell_empty',
        );
      });
    }
  }
}
