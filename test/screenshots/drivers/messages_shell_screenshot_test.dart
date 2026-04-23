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
/// ### Thread-state desktop golden — deferred
///
/// Capturing the master-detail thread state (list + [ChatThreadScreen])
/// on desktop would match `chat_thread_desktop_expanded.png`, but
/// requires fixing a pre-existing bug in `captureScreenshot`'s pump +
/// capture pipeline: when the thread notifier's async `build()` depends
/// on `Future.wait` + a `watchMessages` stream, the capture consistently
/// produces a solid-color image (widget tree is populated but the
/// rendered frame isn't). Evidence: the existing `chat_thread_*`
/// goldens in dev have byte-identical light and dark variants for the
/// same device (e.g. both `chat_thread_en_US_light_android_phone` and
/// `chat_thread_en_US_dark_android_phone` share blob `492a7ff0`), which
/// is physically impossible for a correctly rendered theme-sensitive
/// surface. Fixing the capture path is out of #194 scope — tracked in
/// the umbrella #198 for a dedicated screenshot-infra PR.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/presentation/screens/messages_responsive_shell.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('messages_shell_empty ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const MessagesResponsiveShell(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'messages_shell_empty',
          );
        });
      }
    }
  }
}
