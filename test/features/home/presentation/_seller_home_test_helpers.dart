import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/repositories/message_repository.dart';
import 'package:deelmarkt/core/domain/repositories/transaction_repository.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_actions_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_listings_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_stats_usecase.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository stubs — never called; use cases override call()
// ---------------------------------------------------------------------------

class FakeListingRepo implements ListingRepository {
  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async => [];

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

class FakeMessageRepo implements MessageRepository {
  @override
  Future<List<ConversationEntity>> getConversations() async => [];

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

class FakeTransactionRepo implements TransactionRepository {
  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async =>
      [];

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

// ---------------------------------------------------------------------------
// Stub use cases
// ---------------------------------------------------------------------------

class StubGetSellerStats extends GetSellerStatsUseCase {
  StubGetSellerStats(this.fn)
    : super(
        listingRepository: FakeListingRepo(),
        messageRepository: FakeMessageRepo(),
        transactionRepository: FakeTransactionRepo(),
      );

  final Future<SellerStatsEntity> Function(String) fn;

  @override
  Future<SellerStatsEntity> call(String userId) => fn(userId);
}

class StubGetSellerActions extends GetSellerActionsUseCase {
  StubGetSellerActions(this.fn)
    : super(
        messageRepository: FakeMessageRepo(),
        transactionRepository: FakeTransactionRepo(),
      );

  final Future<List<ActionItemEntity>> Function(String) fn;

  @override
  Future<List<ActionItemEntity>> call(String userId) => fn(userId);
}

class StubGetSellerListings extends GetSellerListingsUseCase {
  StubGetSellerListings(this.fn) : super(FakeListingRepo());

  final Future<List<ListingEntity>> Function(String) fn;

  @override
  Future<List<ListingEntity>> call(String userId, {int limit = 20}) =>
      fn(userId);
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const sellerTestStats = SellerStatsEntity(
  totalSalesCents: 10000,
  activeListingsCount: 3,
  unreadMessagesCount: 1,
);

const sellerTestActions = <ActionItemEntity>[
  ActionItemEntity(
    id: 'a1',
    type: ActionItemType.shipOrder,
    referenceId: 'txn-001',
  ),
];

ListingEntity makeTestListing(String id) => ListingEntity(
  id: id,
  title: 'Listing $id',
  description: 'Desc',
  priceInCents: 1000,
  sellerId: 'seller-1',
  sellerName: 'Seller',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
);

User makeTestUser({
  String id = 'user-1',
  String? email,
  Map<String, dynamic>? userMetadata,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata ?? const {},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
    email: email,
  );
}

Future<ProviderContainer> makeSellerContainer({
  required User? user,
  Future<SellerStatsEntity> Function(String)? statsResult,
  Future<List<ActionItemEntity>> Function(String)? actionsResult,
  Future<List<ListingEntity>> Function(String)? listingsResult,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final stats = statsResult ?? (_) async => sellerTestStats;
  final actions = actionsResult ?? (_) async => sellerTestActions;
  final listings = listingsResult ?? (_) async => [makeTestListing('1')];

  return ProviderContainer(
    overrides: [
      useMockDataProvider.overrideWithValue(true),
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(user),
      getSellerStatsUseCaseProvider.overrideWithValue(
        StubGetSellerStats(stats),
      ),
      getSellerActionsUseCaseProvider.overrideWithValue(
        StubGetSellerActions(actions),
      ),
      getSellerListingsUseCaseProvider.overrideWithValue(
        StubGetSellerListings(listings),
      ),
    ],
  );
}
