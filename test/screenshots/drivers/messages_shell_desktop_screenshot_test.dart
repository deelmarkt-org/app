/// Screenshot driver — Messages master-detail shell on desktop.
///
/// Generates the `messages_desktop_expanded` and `chat_thread_desktop_expanded`
/// goldens required by issue #194 by capturing the shared
/// [MessagesResponsiveShell] at the 1400×900 desktop frame from #192.
///
/// Two conversation states are captured:
///   • `messages_shell_empty`  — no conversation selected (master + empty
///     right pane, matches `messages_desktop_expanded` empty variant).
///   • `messages_shell_thread` — conversation pre-selected (master + thread,
///     matches `messages_desktop_expanded` / `chat_thread_desktop_expanded`
///     data variant).
///
/// Mobile devices are covered by `chat_thread_screenshot_test.dart` and the
/// existing `conversation_list_screen_test.dart` widget tests; this driver
/// scopes to `kScreenshotDesktopDevices` only to keep the generated PNG
/// count proportional to the layout the PR actually changes.
///
/// Spec: docs/screens/06-chat/01-conversation-list.md §Expanded
///       docs/screens/06-chat/02-chat-thread.md §Responsive
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

        testWidgets(
          'messages_shell_thread ${device.id} $locale ${theme.name}',
          (tester) async {
            await captureScreenshot(
              tester: tester,
              screen: const MessagesResponsiveShell(
                conversationId: kScreenshotConversationId,
              ),
              locale: locale,
              theme: theme,
              device: device,
              goldenName: 'messages_shell_thread',
            );
          },
        );
      }
    }
  }
}
