import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/update_offer_status_usecase.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/usecases/_fake_message_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(FakeMessageRepository()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('getMessagesUseCaseProvider resolves', () {
    expect(
      container.read(getMessagesUseCaseProvider),
      isA<GetMessagesUseCase>(),
    );
  });

  test('sendMessageUseCaseProvider resolves', () {
    expect(
      container.read(sendMessageUseCaseProvider),
      isA<SendMessageUseCase>(),
    );
  });

  test('updateOfferStatusUseCaseProvider resolves', () {
    expect(
      container.read(updateOfferStatusUseCaseProvider),
      isA<UpdateOfferStatusUseCase>(),
    );
  });
}
