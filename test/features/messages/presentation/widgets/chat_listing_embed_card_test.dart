import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_listing_embed_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final conversation = ConversationEntity(
    id: 'conv-1',
    listingId: 'listing-1',
    listingTitle: 'Vintage fiets',
    listingImageUrl: null,
    otherUserId: 'user-2',
    otherUserName: 'Jan',
    lastMessageText: 'Hoi',
    lastMessageAt: DateTime(2026),
  );

  Widget buildTest() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: ChatListingEmbedCard(conversation: conversation)),
      ),
    );
  }

  testWidgets('renders listing title', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();

    expect(find.text('Vintage fiets'), findsOneWidget);
  });

  testWidgets('has semantics label containing listing title', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();

    final semantics = tester.getSemantics(find.byType(ChatListingEmbedCard));
    expect(semantics.label, contains('Vintage fiets'));
  });
}
