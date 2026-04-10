import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_actions_usecase.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

class _FakeMessageRepo implements MessageRepository {
  final List<ConversationEntity> _conversations;

  _FakeMessageRepo([this._conversations = const []]);

  @override
  Future<List<ConversationEntity>> getConversations() async => _conversations;

  @override
  Future<List<MessageEntity>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async => [];

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) =>
      const Stream.empty();

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    int? offerAmountCents,
  }) => throw UnimplementedError();

  @override
  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
  }) => throw UnimplementedError();

  @override
  Future<void> updateOfferStatus({
    required String messageId,
    required OfferStatus newStatus,
  }) => throw UnimplementedError();
}

class _FakeTransactionRepo implements TransactionRepository {
  final List<TransactionEntity> _transactions;

  _FakeTransactionRepo([this._transactions = const []]);

  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async =>
      _transactions;

  @override
  Future<TransactionEntity> createTransaction({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  }) => throw UnimplementedError();

  @override
  Future<TransactionEntity?> getTransaction(String id) async => null;

  @override
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  }) => throw UnimplementedError();

  @override
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  }) => throw UnimplementedError();

  @override
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  }) => throw UnimplementedError();
}

TransactionEntity _paidTransaction(String id, String sellerId) =>
    TransactionEntity(
      id: id,
      listingId: 'listing-$id',
      buyerId: 'buyer-1',
      sellerId: sellerId,
      status: TransactionStatus.paid,
      itemAmountCents: 5000,
      platformFeeCents: 125,
      shippingCostCents: 500,
      currency: 'EUR',
      createdAt: DateTime(2026),
    );

ConversationEntity _unreadConversation(String id, {int unreadCount = 1}) =>
    ConversationEntity(
      id: id,
      listingId: 'listing-1',
      listingTitle: 'Test Listing',
      listingImageUrl: null,
      otherUserId: 'other-1',
      otherUserName: 'Koper',
      lastMessageText: 'Hallo!',
      lastMessageAt: DateTime(2026),
      unreadCount: unreadCount,
    );

void main() {
  group('GetSellerActionsUseCase', () {
    test(
      'returns ship orders for paid transactions where user is seller',
      () async {
        final useCase = GetSellerActionsUseCase(
          messageRepository: _FakeMessageRepo(),
          transactionRepository: _FakeTransactionRepo([
            _paidTransaction('tx-1234', 'seller-1'),
          ]),
        );

        final result = await useCase.call('seller-1');

        expect(result.length, 1);
        expect(result.first.type, ActionItemType.shipOrder);
        expect(result.first.id, 'ship-tx-1234');
        expect(result.first.referenceId, 'tx-1234');
      },
    );

    test(
      'returns reply actions for conversations with unread messages',
      () async {
        final useCase = GetSellerActionsUseCase(
          messageRepository: _FakeMessageRepo([
            _unreadConversation('conv-1', unreadCount: 3),
          ]),
          transactionRepository: _FakeTransactionRepo(),
        );

        final result = await useCase.call('seller-1');

        expect(result.length, 1);
        expect(result.first.type, ActionItemType.replyMessage);
        expect(result.first.id, 'reply-conv-1');
      },
    );

    test('skips transactions where user is buyer', () async {
      final useCase = GetSellerActionsUseCase(
        messageRepository: _FakeMessageRepo(),
        transactionRepository: _FakeTransactionRepo([
          _paidTransaction('tx-1', 'other-seller'),
        ]),
      );

      final result = await useCase.call('seller-1');

      expect(result, isEmpty);
    });

    test('skips conversations with zero unread', () async {
      final useCase = GetSellerActionsUseCase(
        messageRepository: _FakeMessageRepo([
          _unreadConversation('conv-1', unreadCount: 0),
        ]),
        transactionRepository: _FakeTransactionRepo(),
      );

      final result = await useCase.call('seller-1');

      expect(result, isEmpty);
    });

    test('returns empty when no actions', () async {
      final useCase = GetSellerActionsUseCase(
        messageRepository: _FakeMessageRepo(),
        transactionRepository: _FakeTransactionRepo(),
      );

      final result = await useCase.call('seller-1');

      expect(result, isEmpty);
    });

    test('ship orders appear before reply actions', () async {
      final useCase = GetSellerActionsUseCase(
        messageRepository: _FakeMessageRepo([_unreadConversation('conv-1')]),
        transactionRepository: _FakeTransactionRepo([
          _paidTransaction('tx-1', 'seller-1'),
        ]),
      );

      final result = await useCase.call('seller-1');

      expect(result.length, 2);
      expect(result.first.type, ActionItemType.shipOrder);
      expect(result.last.type, ActionItemType.replyMessage);
    });
  });
}
