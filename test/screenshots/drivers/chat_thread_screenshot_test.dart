/// Screenshot driver — Chat thread screen.
///
/// Hero screen #6: scam-alert safety features.
/// Spec: docs/screens/06-chat/02-chat-thread.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';

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
}
