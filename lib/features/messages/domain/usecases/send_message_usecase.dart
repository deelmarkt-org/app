import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Sends a message in a conversation.
///
/// Trims whitespace and rejects empty text with an [ArgumentError].
/// Defaults to [MessageType.text]; callers may override for offers.
class SendMessageUseCase {
  const SendMessageUseCase(this._repo);

  final MessageRepository _repo;

  Future<MessageEntity> call({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message text must not be empty');
    }
    return _repo.sendMessage(
      conversationId: conversationId,
      text: trimmed,
      type: type,
    );
  }
}
