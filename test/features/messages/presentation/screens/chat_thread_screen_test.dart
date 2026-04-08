import 'dart:async';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/make_offer_sheet.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/message_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_chat_thread_test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ChatThreadScreen', () {
    testWidgets('shows progress indicator while loading', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<ConversationEntity>>();
      final hanging = HangingRepo(completer.future);
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

      final throwing = ThrowingRepo();
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

    testWidgets('offer button opens MakeOfferSheet', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.byType(MakeOfferSheet), findsOneWidget);
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
}
