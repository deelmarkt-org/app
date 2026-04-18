import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/update_offer_status_usecase.dart';

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(messageRepositoryProvider)),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(messageRepositoryProvider)),
);

final updateOfferStatusUseCaseProvider = Provider<UpdateOfferStatusUseCase>(
  (ref) => UpdateOfferStatusUseCase(ref.watch(messageRepositoryProvider)),
);
