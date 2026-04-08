import 'dart:async';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/message_bubble.dart';
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

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  ConversationEntity conv(String id) => ConversationEntity(
    id: id,
    listingId: 'l-$id',
    listingTitle: 'Canyon Speedmax',
    listingImageUrl: null,
    otherUserId: 'other-$id',
    otherUserName: 'Jan de Vries',
    lastMessageText: 'hi',
    lastMessageAt: DateTime(2026, 3, 25, 14),
  );

  MessageEntity msg(
    String id,
    DateTime at, {
    String sender = 'user-001',
    String text = 'Hallo',
  }) => MessageEntity(
    id: id,
    conversationId: 'c1',
    senderId: sender,
    text: text,
    createdAt: at,
  );

  Widget buildApp({
    required FakeMessageRepository repo,
    String conversationId = 'c1',
    ThemeData? theme,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [messageRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: Scaffold(
            body: ChatThreadScreen(conversationId: conversationId),
          ),
        ),
      ),
    );
  }

  group('ChatThreadScreen', () {
    testWidgets('shows progress indicator while loading', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<ConversationEntity>>();
      final hanging = _HangingRepo(completer.future);
      await tester.pumpWidget(buildApp(repo: hanging));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([conv('c1')]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders header, listing embed, and messages on success', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          msg('m1', DateTime(2026, 3, 25, 10), text: 'Hoi'),
          msg('m2', DateTime(2026, 3, 25, 11), sender: 'other-c1'),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ChatHeader), findsOneWidget);
      expect(find.byType(ChatListingEmbedCard), findsOneWidget);
      expect(find.byType(ChatMessageComposer), findsOneWidget);
      expect(find.byType(MessageBubble), findsNWidgets(2));
    });

    testWidgets('renders error state with retry', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final throwing = _ThrowingRepo();
      await tester.pumpWidget(buildApp(repo: throwing));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders empty-thread placeholder when no messages', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(MessageBubble), findsNothing);
      expect(find.byType(ChatMessageComposer), findsOneWidget);
    });

    testWidgets('sending a message clears the input and appends a bubble', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Goedemiddag');
      await tester.pump();
      // Tap the send button (it's the only circular InkWell with arrow_upward)
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(find.text('Goedemiddag'), findsOneWidget);
      expect(repo.sendCalls, hasLength(1));
      expect(repo.sendCalls.single.text, 'Goedemiddag');
    });

    testWidgets('camera button shows coming soon snackbar', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('offer button shows coming soon snackbar', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('chat.offer'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [msg('m1', DateTime(2026, 3, 25, 10))],
      );
      await tester.pumpWidget(buildApp(repo: repo, theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(MessageBubble), findsOneWidget);
    });
  });

  group('ChatMessageComposer', () {
    Widget wrap(Widget child) => EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: child),
      ),
    );

    testWidgets('send button is disabled on empty input', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: false, onSend: sent.add)),
      );
      await tester.pumpAndSettle();

      // Tapping the send icon should NOT fire onSend
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('send button fires with trimmed text and clears input', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: false, onSend: sent.add)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Hallo wereld  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(sent, ['  Hallo wereld  ']);
      // After send the controller is cleared
      expect(
        (tester.widget(find.byType(TextField)) as TextField).controller?.text,
        isEmpty,
      );
    });

    testWidgets('shows progress indicator when isSending is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: true, onSend: (_) {})),
      );
      // Don't pumpAndSettle — CircularProgressIndicator animates indefinitely.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _ThrowingRepo extends FakeMessageRepository {
  @override
  Future<List<ConversationEntity>> getConversations() async {
    throw StateError('network down');
  }
}

class _HangingRepo extends FakeMessageRepository {
  _HangingRepo(this._future);
  final Future<List<ConversationEntity>> _future;

  @override
  Future<List<ConversationEntity>> getConversations() => _future;
}
