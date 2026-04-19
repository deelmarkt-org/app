import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_stats_usecase.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

class _FakeListingRepo implements ListingRepository {
  final List<ListingEntity> _listings;

  _FakeListingRepo([this._listings = const []]);

  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async => _listings.take(limit).toList();

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async => [];

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async => [];

  @override
  Future<ListingEntity?> getById(String id) async => null;

  @override
  Future<ListingSearchResult> search({
    required String query,
    String? categoryId,
    List<String>? categoryIds,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    String? sortBy,
    bool ascending = false,
    int offset = 0,
    int limit = 20,
  }) async =>
      const ListingSearchResult(listings: [], total: 0, offset: 0, limit: 20);

  @override
  Future<ListingEntity> toggleFavourite(String listingId) =>
      throw UnimplementedError();

  @override
  Future<List<ListingEntity>> getFavourites() async => [];
}

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

ListingEntity _listing(
  String id, {
  ListingStatus status = ListingStatus.active,
}) => ListingEntity(
  id: id,
  title: 'Item $id',
  description: 'Description',
  priceInCents: 5000,
  sellerId: 'seller-1',
  sellerName: 'Seller',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
  status: status,
);

TransactionEntity _transaction(
  String id, {
  required String sellerId,
  required TransactionStatus status,
  int itemAmountCents = 5000,
}) => TransactionEntity(
  id: id,
  listingId: 'listing-$id',
  buyerId: 'buyer-1',
  sellerId: sellerId,
  status: status,
  itemAmountCents: itemAmountCents,
  platformFeeCents: 125,
  shippingCostCents: 500,
  currency: 'EUR',
  createdAt: DateTime(2026),
);

ConversationEntity _conversation(String id, {int unreadCount = 0}) =>
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
  group('GetSellerStatsUseCase', () {
    test('computes stats from all repositories', () async {
      final useCase = GetSellerStatsUseCase(
        listingRepository: _FakeListingRepo([
          _listing('1'),
          _listing('2'),
          _listing('3', status: ListingStatus.sold),
        ]),
        messageRepository: _FakeMessageRepo([
          _conversation('c1', unreadCount: 2),
          _conversation('c2'),
          _conversation('c3', unreadCount: 1),
        ]),
        transactionRepository: _FakeTransactionRepo([
          _transaction(
            't1',
            sellerId: 'seller-1',
            status: TransactionStatus.released,
          ),
          _transaction(
            't2',
            sellerId: 'seller-1',
            status: TransactionStatus.resolved,
            itemAmountCents: 3000,
          ),
        ]),
      );

      final stats = await useCase.call('seller-1');

      expect(stats.activeListingsCount, 2);
      expect(stats.totalSalesCents, 8000);
      // Bug #115 fix: sum of unreadCount per conversation (2+0+1=3), not count of
      // conversations that have unread messages.
      expect(stats.unreadMessagesCount, 3);
    });

    test('returns zero stats when all repos empty', () async {
      final useCase = GetSellerStatsUseCase(
        listingRepository: _FakeListingRepo(),
        messageRepository: _FakeMessageRepo(),
        transactionRepository: _FakeTransactionRepo(),
      );

      final stats = await useCase.call('seller-1');

      expect(stats.activeListingsCount, 0);
      expect(stats.totalSalesCents, 0);
      expect(stats.unreadMessagesCount, 0);
    });

    test('only counts released and resolved transactions for seller', () async {
      final useCase = GetSellerStatsUseCase(
        listingRepository: _FakeListingRepo(),
        messageRepository: _FakeMessageRepo(),
        transactionRepository: _FakeTransactionRepo([
          _transaction(
            't1',
            sellerId: 'seller-1',
            status: TransactionStatus.paid,
          ),
          _transaction(
            't2',
            sellerId: 'seller-1',
            status: TransactionStatus.shipped,
            itemAmountCents: 3000,
          ),
          _transaction(
            't3',
            sellerId: 'other-seller',
            status: TransactionStatus.released,
            itemAmountCents: 9000,
          ),
        ]),
      );

      final stats = await useCase.call('seller-1');

      expect(stats.totalSalesCents, 0);
    });
  });
}
