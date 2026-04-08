import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';

/// Stub id for the current signed-in user.
///
/// TODO(auth): replace with `authStateProvider.currentUser.id` once the auth
/// subsystem ships via the `[R]` backend tasks. This single constant is the
/// source of truth for both the notifier (optimistic send sender) and the
/// screen (self vs other bubble alignment).
const String kCurrentUserIdStub = 'user-001';

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(messageRepositoryProvider)),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(messageRepositoryProvider)),
);
