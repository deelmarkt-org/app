import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_scam_alert_slot.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_thread_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConversationEntity _conv() => ConversationEntity(
  id: 'c1',
  listingId: 'l1',
  listingTitle: 'Canyon Speedmax',
  listingImageUrl: null,
  otherUserId: 'other-001',
  otherUserName: 'Jan',
  lastMessageText: 'hi',
  lastMessageAt: DateTime(2026, 3, 25, 14),
);

ChatThreadState _state() =>
    ChatThreadState(conversation: _conv(), messages: const []);

Widget _buildTest(ChatThreadState state) {
  return ProviderScope(
    child: EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ChatThreadBody(
                  state: state,
                  colors: ChatThemeColors.of(context),
                  scrollController: ScrollController(),
                  currentUserId: 'user-001',
                  showBackButton: true,
                  onOfferRespond: (_, _) {},
                  onSend: (_) {},
                  onCameraTap: () {},
                  onMakeOfferTap: () {},
                ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ChatThreadBody', () {
    testWidgets('renders without exception', (tester) async {
      await tester.pumpWidget(_buildTest(_state()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('contains ChatHeader', (tester) async {
      await tester.pumpWidget(_buildTest(_state()));
      await tester.pumpAndSettle();

      expect(find.byType(ChatHeader), findsOneWidget);
    });

    testWidgets('contains ChatListingEmbedCard', (tester) async {
      await tester.pumpWidget(_buildTest(_state()));
      await tester.pumpAndSettle();

      expect(find.byType(ChatListingEmbedCard), findsOneWidget);
    });

    testWidgets('contains ChatScamAlertSlot', (tester) async {
      await tester.pumpWidget(_buildTest(_state()));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScamAlertSlot), findsOneWidget);
    });

    testWidgets('contains ChatMessageComposer', (tester) async {
      await tester.pumpWidget(_buildTest(_state()));
      await tester.pumpAndSettle();

      expect(find.byType(ChatMessageComposer), findsOneWidget);
    });
  });
}
