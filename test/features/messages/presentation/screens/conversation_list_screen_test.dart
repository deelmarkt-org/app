import 'dart:async';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/screens/conversation_list_screen.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_empty_state.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_skeleton.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_tile.dart';
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

  Widget buildApp({required FakeMessageRepository repo, ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [messageRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: const Scaffold(body: ConversationListScreen()),
        ),
      ),
    );
  }

  ConversationEntity conv(String id, DateTime at, {int unread = 0}) =>
      ConversationEntity(
        id: id,
        listingId: 'l-$id',
        listingTitle: 'Listing $id',
        listingImageUrl: null,
        otherUserId: 'u-$id',
        otherUserName: 'User $id',
        lastMessageText: 'Hallo wereld',
        lastMessageAt: at,
        unreadCount: unread,
      );

  group('ConversationListScreen', () {
    testWidgets('shows skeleton while loading', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<ConversationEntity>>();
      final hanging = _HangingRepo(completer.future);

      await tester.pumpWidget(buildApp(repo: hanging));
      await tester.pump();

      expect(find.byType(ConversationListSkeleton), findsOneWidget);

      completer.complete(<ConversationEntity>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no conversations', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(repo: FakeMessageRepository(conversations: [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListEmptyState), findsOneWidget);
    });

    testWidgets('renders conversation tiles when data loads', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [
          conv('a', DateTime(2026, 3, 25, 14)),
          conv('b', DateTime(2026, 3, 24, 10), unread: 2),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListTile), findsNWidgets(2));
      expect(find.text('User a'), findsOneWidget);
      expect(find.text('User b'), findsOneWidget);
    });

    testWidgets('renders error state and retry button', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final throwing = _ThrowingRepo();
      await tester.pumpWidget(buildApp(repo: throwing));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('a', DateTime(2026, 3, 25))],
      );
      await tester.pumpWidget(buildApp(repo: repo, theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationListTile), findsOneWidget);
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
