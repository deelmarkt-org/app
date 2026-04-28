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
  // Fixed in screenshot_driver.dart: a pump() between pumpWidget and
  // pump(600ms) processes EasyLocalization's platform message so the screen
  // builds before the fake clock advances — mock repo timers then fire
  // within the 600ms window and ChatThreadNotifier resolves to loaded state.
  group('canary — loaded-state baseline (#203)', () {
    // First iteration: verifies the AsyncNotifier resolves to loaded state.
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
              'not commit to the Element tree before golden capture.',
        );
      },
    );

    // Second iteration: verifies the #203 test-isolation fix — a second
    // captureScreenshot call (different locale + theme) within the same test
    // must also produce a loaded widget tree, not a blank/skeleton.
    testWidgets(
      'chat_thread second iteration still renders MessageBubble (#203 regression guard)',
      (tester) async {
        await captureScreenshot(
          tester: tester,
          screen: const ChatThreadScreen(
            conversationId: kScreenshotConversationId,
          ),
          locale: 'en_US',
          theme: ScreenshotTheme.dark,
          device: kScreenshotDevices.first,
          goldenName: 'chat_thread_canary_dark',
        );

        expect(
          find.byType(MessageBubble),
          findsAtLeastNWidgets(1),
          reason:
              'Second captureScreenshot call must also resolve to loaded state. '
              'A transparent canvas or skeleton state here indicates the #203 '
              'test-isolation defect is still present in screenshot_driver.dart.',
        );
      },
    );
  });
}
