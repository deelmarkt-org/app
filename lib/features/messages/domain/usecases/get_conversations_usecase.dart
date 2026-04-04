import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Fetches all conversations for the current user.
///
/// Sorts the result by [ConversationEntity.lastMessageAt] descending
/// (most recent first) so the UI does not have to.
///
/// Domain layer — pure Dart, no Flutter or Supabase imports.
class GetConversationsUseCase {
  const GetConversationsUseCase(this._repo);

  final MessageRepository _repo;

  Future<List<ConversationEntity>> call() async {
    final conversations = await _repo.getConversations();
    final sorted = [...conversations]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return sorted;
  }
}
