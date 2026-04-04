import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:deelmarkt/features/messages/presentation/screens/conversation_list_screen.dart';
import 'package:deelmarkt/features/messages/presentation/screens/messages_responsive_shell.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/no_thread_selected.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/usecases/_fake_message_repository.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  ConversationEntity conv(String id) => ConversationEntity(
    id: id,
    listingId: 'l-$id',
    listingTitle: 'Title $id',
    listingImageUrl: null,
    otherUserId: 'u-$id',
    otherUserName: 'User $id',
    lastMessageText: 'hi',
    lastMessageAt: DateTime(2026, 3, 25),
  );

  Widget buildApp({
    required FakeMessageRepository repo,
    required String? conversationId,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [messageRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: MessagesResponsiveShell(conversationId: conversationId),
        ),
      ),
    );
  }

  void setViewport(WidgetTester tester, {required double width}) {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1.0;
  }

  group('MessagesResponsiveShell — compact layout', () {
    testWidgets('shows only the list when no conversationId', (tester) async {
      setViewport(tester, width: 375);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(
          repo: FakeMessageRepository(conversations: [conv('a')]),
          conversationId: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListScreen), findsOneWidget);
      expect(find.byType(ChatThreadScreen), findsNothing);
      expect(find.byType(NoThreadSelected), findsNothing);
    });

    testWidgets('shows only the thread when conversationId set', (
      tester,
    ) async {
      setViewport(tester, width: 375);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(
          repo: FakeMessageRepository(conversations: [conv('a')]),
          conversationId: 'a',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatThreadScreen), findsOneWidget);
      expect(find.byType(ConversationListScreen), findsNothing);
    });
  });

  group('MessagesResponsiveShell — expanded layout', () {
    testWidgets('shows list + empty right pane when no id', (tester) async {
      setViewport(tester, width: 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(
          repo: FakeMessageRepository(conversations: [conv('a')]),
          conversationId: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListScreen), findsOneWidget);
      expect(find.byType(NoThreadSelected), findsOneWidget);
      expect(find.byType(ChatThreadScreen), findsNothing);
    });

    testWidgets('shows list + thread when id provided', (tester) async {
      setViewport(tester, width: 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(
          repo: FakeMessageRepository(conversations: [conv('a'), conv('b')]),
          conversationId: 'a',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListScreen), findsOneWidget);
      expect(find.byType(ChatThreadScreen), findsOneWidget);
      expect(find.byType(NoThreadSelected), findsNothing);
    });
  });
}
