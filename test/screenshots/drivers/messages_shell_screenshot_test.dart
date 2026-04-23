/// Screenshot driver — Messages master-detail shell on desktop.
///
/// Mobile messages UX is already covered by the standalone
/// [ConversationListScreen] / [ChatThreadScreen] drivers. This driver
/// captures the DESKTOP layout introduced in #194 (master-detail via
/// `ResponsiveDetailScaffold`), matching:
/// - `docs/screens/06-chat/designs/messages_desktop_expanded.png` —
///   list + "pick a conversation" empty state (no `conversationId`).
/// - `docs/screens/06-chat/designs/chat_thread_desktop_expanded.png` —
///   list + thread side-by-side (`conversationId` set).
///
/// Only iterates `kScreenshotDesktopDevices` because the shell's
/// compact/mobile behaviour is identical to the standalone screens
/// already covered elsewhere.
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
