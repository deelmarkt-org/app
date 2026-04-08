import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/_fake_message_repository.dart';

export '../../domain/usecases/_fake_message_repository.dart';

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

MessageEntity offerMsg(
  String id,
  DateTime at, {
  String sender = 'other-c1',
  int amountCents = 12000,
  OfferStatus offerStatus = OfferStatus.pending,
}) => MessageEntity(
  id: id,
  conversationId: 'c1',
  senderId: sender,
  text: (amountCents / 100).toStringAsFixed(2),
  type: MessageType.offer,
  offerAmountCents: amountCents,
  offerStatus: offerStatus,
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
        home: Scaffold(body: ChatThreadScreen(conversationId: conversationId)),
      ),
    ),
  );
}

class ThrowingRepo extends FakeMessageRepository {
  @override
  Future<List<ConversationEntity>> getConversations() async {
    throw StateError('network down');
  }
}

class HangingRepo extends FakeMessageRepository {
  HangingRepo(this._future);
  final Future<List<ConversationEntity>> _future;

  @override
  Future<List<ConversationEntity>> getConversations() => _future;
}
