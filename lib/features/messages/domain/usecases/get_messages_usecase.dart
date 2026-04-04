import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Fetches all messages in a conversation, ordered oldest → newest.
///
/// The UI renders messages chronologically (top = oldest), so ordering
/// is part of the domain contract, not a widget concern.
class GetMessagesUseCase {
  const GetMessagesUseCase(this._repo);

  final MessageRepository _repo;

  Future<List<MessageEntity>> call(String conversationId) async {
    final messages = await _repo.getMessages(conversationId);
    final sorted = [...messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }
}
