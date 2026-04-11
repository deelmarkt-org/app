import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/core/domain/repositories/message_repository.dart';
import 'package:deelmarkt/core/domain/repositories/transaction_repository.dart';

/// Composes seller dashboard statistics from listings, messages,
/// and transactions repositories.
///
/// Uses [Future.wait] for parallel fetching (audit finding A2).
class GetSellerStatsUseCase {
  const GetSellerStatsUseCase({
    required ListingRepository listingRepository,
    required MessageRepository messageRepository,
    required TransactionRepository transactionRepository,
  }) : _listingRepo = listingRepository,
       _messageRepo = messageRepository,
       _transactionRepo = transactionRepository;

  final ListingRepository _listingRepo;
  final MessageRepository _messageRepo;
  final TransactionRepository _transactionRepo;

  Future<SellerStatsEntity> call(String userId) async {
    // limit: 100 is an intentional cap for the dashboard stats card.
    // The active listings count is therefore approximate for prolific sellers
    // (>100 listings). A dedicated countActiveListings repository method
    // is tracked in P-54 for a future sprint.
    final (listings, conversations, transactions) =
        await (
          _listingRepo.getByUserId(userId, limit: 100),
          _messageRepo.getConversations(),
          _transactionRepo.getTransactionsForUser(userId),
        ).wait;

    final activeCount =
        listings.where((l) => l.status == ListingStatus.active).length;

    final totalSalesCents = transactions
        .where(
          (t) =>
              t.sellerId == userId &&
              (t.status == TransactionStatus.released ||
                  t.status == TransactionStatus.resolved),
        )
        .fold<int>(0, (sum, t) => sum + t.itemAmountCents);

    final unreadCount = conversations.where((c) => c.unreadCount > 0).length;

    return SellerStatsEntity(
      totalSalesCents: totalSalesCents,
      activeListingsCount: activeCount,
      unreadMessagesCount: unreadCount,
    );
  }
}
