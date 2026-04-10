import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/core/domain/repositories/message_repository.dart';
import 'package:deelmarkt/core/domain/repositories/transaction_repository.dart';

/// Fetches pending actions for the seller: orders to ship and messages to reply.
///
/// Returns [ActionItemEntity] list sorted by urgency (ship orders first).
class GetSellerActionsUseCase {
  const GetSellerActionsUseCase({
    required MessageRepository messageRepository,
    required TransactionRepository transactionRepository,
  }) : _messageRepo = messageRepository,
       _transactionRepo = transactionRepository;

  final MessageRepository _messageRepo;
  final TransactionRepository _transactionRepo;

  Future<List<ActionItemEntity>> call(String userId) async {
    final (transactions, conversations) =
        await (
          _transactionRepo.getTransactionsForUser(userId),
          _messageRepo.getConversations(),
        ).wait;

    final actions = <ActionItemEntity>[];

    for (final t in transactions) {
      if (t.sellerId == userId && t.status == TransactionStatus.paid) {
        actions.add(
          ActionItemEntity(
            id: 'ship-${t.id}',
            type: ActionItemType.shipOrder,
            referenceId: t.id,
          ),
        );
      }
    }

    for (final c in conversations) {
      if (c.unreadCount > 0) {
        actions.add(
          ActionItemEntity(
            id: 'reply-${c.id}',
            type: ActionItemType.replyMessage,
            referenceId: c.id,
            otherUserName: c.otherUserName,
            unreadCount: c.unreadCount,
          ),
        );
      }
    }

    return actions;
  }
}
