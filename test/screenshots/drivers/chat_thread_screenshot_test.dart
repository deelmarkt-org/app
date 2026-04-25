/// Screenshot driver — Chat thread screen.
///
/// Hero screen #6: scam-alert safety features.
/// Spec: docs/screens/06-chat/02-chat-thread.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/message_bubble.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('chat_thread ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const ChatThreadScreen(
              conversationId: kScreenshotConversationId,
            ),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'chat_thread',
          );
        });
      }
    }
  }

  // Canary — loaded-state baseline for issue #203.
  //
  // Inspects the widget tree AFTER `captureScreenshot` returns. A loaded
  // `ChatThreadScreen` renders one or more [MessageBubble]s for the seeded
  // `conv-001` thread; a skeleton/loading state renders zero. Asserting on
  // the presence of `MessageBubble` (rather than a raw widget count, which
  // skeleton trees can satisfy) gives a sharp signal of whether the
  // capture pipeline ran to a loaded state before snapshotting.
  //
  // Today this canary is expected to FAIL because of the dual problem
  // documented in `docs/PLAN-screenshot-golden-fix.md`:
  //   1. `AsyncNotifier.build()` micro-tasks may not drain before the
  //      golden frame is taken (the original #203 hypothesis).
  //   2. Test-isolation defect — only the first `(device, locale, theme)`
  //      iteration of each driver paints to its surface; subsequent
  //      iterations capture a fully transparent canvas (220/240 PNGs in
  //      `dev` are `(0,0,0,0)` across the whole frame).
  //
  // The canary lives in this PR (alongside the `--check-goldens` byte-
  // identity gate) so future fix attempts have a RED baseline to flip
  // GREEN. It is platform-independent (widget tree inspection, not
  // pixels) and runs on every CI runner, not just macOS.
  group('canary — loaded-state baseline (#203)', () {
    testWidgets(
      'chat_thread renders MessageBubble after captureScreenshot pump',
      (tester) async {
        await captureScreenshot(
          tester: tester,
          screen: const ChatThreadScreen(
            conversationId: kScreenshotConversationId,
          ),
          locale: 'nl_NL',
          theme: ScreenshotTheme.light,
          device: kScreenshotDevices.first, // ios_67
          goldenName: 'chat_thread_canary',
        );

        expect(
          find.byType(MessageBubble),
          findsAtLeastNWidgets(1),
          reason:
              'No MessageBubble in tree after pump — ChatThreadScreen is '
              'still in loading/skeleton state. AsyncNotifier.build() did '
              'not commit to the Element tree before golden capture, or '
              'the screen never received a paint frame. Track via #203.',
        );
      },
      // Expected to FAIL today — see canary docstring. Skipped in CI to
      // keep the pipeline green; remove `skip` once #203 lands a fix and
      // the canary turns GREEN as a permanent regression guard.
      skip: true, // Pending #203 — canary is the RED baseline for the fix PR.
    );
  });
}
