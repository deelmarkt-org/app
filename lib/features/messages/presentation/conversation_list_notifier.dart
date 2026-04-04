import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_conversations_usecase.dart';

part 'conversation_list_notifier.g.dart';

/// DI for [GetConversationsUseCase].
final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>(
  (ref) => GetConversationsUseCase(ref.watch(messageRepositoryProvider)),
);

/// Async view-model for the conversation list screen (P-35).
///
/// State transitions: `loading` → `data | error`. Pull-to-refresh calls
/// [refresh] which re-runs the use case and re-enters the loading state
/// while the fetch is in flight.
@riverpod
class ConversationListNotifier extends _$ConversationListNotifier {
  @override
  Future<List<ConversationEntity>> build() => _fetch();

  Future<List<ConversationEntity>> _fetch() {
    final usecase = ref.read(getConversationsUseCaseProvider);
    return usecase();
  }

  /// Pull-to-refresh handler.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
