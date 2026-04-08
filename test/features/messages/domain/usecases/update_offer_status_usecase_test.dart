import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/usecases/update_offer_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_message_repository.dart';

void main() {
  group('UpdateOfferStatusUseCase', () {
    late FakeMessageRepository repo;
    late UpdateOfferStatusUseCase useCase;

    setUp(() {
      repo = FakeMessageRepository();
      useCase = UpdateOfferStatusUseCase(repo);
    });

    test('calls repo with accepted status', () async {
      await useCase(messageId: 'msg-1', newStatus: OfferStatus.accepted);

      expect(repo.updateOfferCalls, hasLength(1));
      expect(repo.updateOfferCalls.single.messageId, 'msg-1');
      expect(repo.updateOfferCalls.single.newStatus, OfferStatus.accepted);
    });

    test('calls repo with declined status', () async {
      await useCase(messageId: 'msg-2', newStatus: OfferStatus.declined);

      expect(repo.updateOfferCalls.single.newStatus, OfferStatus.declined);
    });

    test('throws ArgumentError for empty messageId', () {
      expect(
        () => useCase(messageId: '', newStatus: OfferStatus.accepted),
        throwsArgumentError,
      );
      expect(
        () => useCase(messageId: '   ', newStatus: OfferStatus.accepted),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for pending status (invalid transition)', () {
      expect(
        () => useCase(messageId: 'msg-1', newStatus: OfferStatus.pending),
        throwsArgumentError,
      );
    });
  });
}
