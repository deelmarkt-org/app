import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Minimal in-memory fake for use-case and notifier tests.
///
/// Avoids the mocktail dependency for trivial happy-path suites.
class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository({
    List<ConversationEntity> conversations = const [],
    List<MessageEntity> messages = const [],
    this.throwOnSend = false,
  }) : _conversations = [...conversations],
       _messages = [...messages];

  final List<ConversationEntity> _conversations;
  final List<MessageEntity> _messages;
  final bool throwOnSend;

  /// Records every [sendMessage] invocation for assertions.
  final List<MessageEntity> sendCalls = [];

  @override
  Future<List<ConversationEntity>> getConversations() async => _conversations;

  @override
  Future<List<MessageEntity>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    var all =
        _messages.where((m) => m.conversationId == conversationId).toList();
    if (offset != null) all = all.skip(offset).toList();
    if (limit != null) all = all.take(limit).toList();
    return all;
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) async* {
    yield _messages.where((m) => m.conversationId == conversationId).toList();
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    int? offerAmountCents,
  }) async {
    if (throwOnSend) {
      throw StateError('Network error');
    }
    final msg = MessageEntity(
      id: 'msg-fake-${_messages.length + 1}',
      conversationId: conversationId,
      senderId: 'user-001',
      text: text,
      type: type,
      offerAmountCents: offerAmountCents,
      createdAt: DateTime.now(),
    );
    sendCalls.add(msg);
    _messages.add(msg);
    return msg;
  }

  @override
  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
  }) async => 'conv-fake-001';
}
